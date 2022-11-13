//: [Previous](@previous)

import Foundation

// MARK: - 1.6-1.8 クロージャー形式のメソッドを非同期関数にラップする

/// 例外を投げない非同期関数を作成する.
///
/// 例外を投げない場合は `withCheckedContinuation` 関数を利用する.
enum UseWithCheckedContinuation {
    struct Response {}

    /// ラップ対象のメソッド.
    func fetch(completion: @escaping ((Response) -> Void)) {
        completion(Response())
    }

    /// ラップした非同期メソッド.
    func wrappedFetch() async -> Response {
        await withCheckedContinuation { continuation in
            // continuation は CheckedContinuation 型で、同期関数と非同期関数の橋渡しをするもの.
            fetch { response in
                continuation.resume(returning: response)
            }
        }
    }

    func run() {
        // ラップしたものを呼び出すときはこんな感じ.
        Task.detached {
            let response = await wrappedFetch()
            print(response)
        }
    }
}

/// 例外を投げる非同期関数を作成する.
///
/// 例外を投げる場合は `withCheckedThrowingContinuation` 関数を利用する.
enum UseWithCheckedThrowingContinuation {
    struct Response {}

    /// ラップ対象のメソッド.
    func request(with urlString: String, completion: @escaping ((Result<Response, Error>) -> Void)) {
        completion(.success(Response()))
    }

    /// ラップした非同期メソッド.
    func wrappedRequest(with urlString: String) async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            // continuation は同じく CheckedContinuation 型.
            request(with: urlString) { result in
                continuation.resume(with: result)
            }
        }
    }

    func run() {
        Task.detached {
            let result = try await wrappedRequest(with: "")
            print(result)
        }
    }
}

//: [Next](@next)
