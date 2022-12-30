//: [Previous](@previous)

import CoreLocation
import Foundation

// MARK: - Async Stream

// 既存の非同期シーケンス処理を AsyncStream でラップして async/await で扱えるようにする.

final class LocationManager: NSObject, ObservableObject {

    private let locationManager = CLLocationManager()
    /// デリゲートメソッドからも呼べるようにプロパティで保持しておく
    private var continuation: AsyncStream<CLLocationCoordinate2D>.Continuation? {
        didSet {
            // シーケンスが途中でキャンセルされるなどで終了した時の処理
            continuation?.onTermination = { @Sendable [weak self] _ in
                self?.locationManager.stopUpdatingLocation()
            }
        }
    }

    /// Combine ならこれで利用側に定期的にデータを伝える.
    @Published
    var coordinate = CLLocationCoordinate2D()
    /// async/await なら `AsyncStream` でラップしてあげる.
    var locations: AsyncStream<CLLocationCoordinate2D> {
        AsyncStream { [weak self] continuation in
            // AsyncStream<T>.Continuation を操作することでイテレーションを回す際の値を送信する.
            self?.continuation = continuation
        }
    }

    func setup() {
        // 位置情報取得の許諾など
        locationManager.delegate = self
    }

    func startLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopLocation() {
        locationManager.stopUpdatingLocation()
        // シーケンスを終了する場合は `.finish()` を利用する.
        continuation?.finish()
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        coordinate = location.coordinate
        // シーケンスに次の値を送信
        continuation?.yield(location.coordinate)
    }
}

Task {
    let locationManager = LocationManager()
    // このコードには問題ないが、1 つの AsyncStream に対して複数の Task から next を呼び出すとランタイムエラーになる
    // Fatal error: attempt to await next() on more than on task
    for await coordinate in locationManager.locations {
        print(coordinate)
    }
}

// 例外を投げる場合の実装

final class ThrowableLocationManager: NSObject, ObservableObject {

    struct LocationError: Error {
        let message: String
    }

    private let locationManager = CLLocationManager()
    private var continuation: AsyncThrowingStream<CLLocationCoordinate2D, Error>.Continuation? {
        didSet {
            continuation?.onTermination = { @Sendable [weak self] _ in
                self?.locationManager.stopUpdatingLocation()
            }
        }
    }

    var locations: AsyncThrowingStream<CLLocationCoordinate2D, Error> {
        AsyncThrowingStream { [weak self] continuation in
            guard let self = self else { return }
            switch self.locationManager.authorizationStatus {
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .denied, .restricted:
                continuation.finish(throwing: LocationError(message: "位置情報を許可してください"))
            default:
                break
            }
            self.continuation = continuation
        }
    }

    func startLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopLocation() {
        locationManager.stopUpdatingLocation()
        // `nil` を渡して通常終了させる.
        continuation?.finish(throwing: nil)
    }
}

extension ThrowableLocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            continuation?.finish(throwing: LocationError(message: "位置情報がありません"))
            return
        }
        continuation?.yield(location.coordinate)
    }
}

Task {
    let locationManager = ThrowableLocationManager()

    do {
        for try await coordinate in locationManager.locations {
            print(coordinate)
        }
    } catch {
        print(error.localizedDescription)
    }
}

//: [Next](@next)
