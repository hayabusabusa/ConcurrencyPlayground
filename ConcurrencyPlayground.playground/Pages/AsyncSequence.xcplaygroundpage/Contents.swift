//: [Previous](@previous)

import UIKit
import CoreLocation

// MARK: - AsyncSequence

// Swift Concurrency 非同期処理を反復して記述できる方法を提供している.
// それが for await in ループで for in と同じように扱うことができる.

/// iOS15 で追加された `for await in` が使える API を使ってみる.
enum iOS15APIs {
    /// ファイルの内容を1行ずつ読み込むことができる `URL.lins` を使ってみる.
    func lines() {
        Task {
            guard let url = Bundle.main.url(forResource: "text", withExtension: "txt") else { return }

            var text = ""
            do {
                for try await line in url.lines {
                    // 通常の for in と同じく continue や break が使える.
                    if line == "apple" {
                        continue
                    }

                    if line == "five" {
                        break
                    }

                    text += "\(line)\n"
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    /// `NotificationCenter` に追加されたイベントの発行と購読ができる `notifications` メソッドを使ってみる.
    func notifications() {
        Task {
            let willEnterForeground = await NotificationCenter.default.notifications(named: UIApplication.willEnterForegroundNotification)

            for await notification in willEnterForeground {
                // これでイベントが通知されるたびにここが実行される.
                print(notification)
            }
        }

        // キャンセルを考慮したい場合は Task を保持しておく
        let task = Task {
            let didEnterBackground = await NotificationCenter.default.notifications(named: UIApplication.didEnterBackgroundNotification)
            for await notification in didEnterBackground {
                print(notification)
            }
        }

        // キャンセルしたい時に cancel する
        task.cancel()
    }
}

/// 独自の型を `AsyncSequence` プロトコルに準拠させて `for await in` を使えるようにする.
enum DefineCustomAsyncSequence {
    struct Counter {
        struct AsyncCounter: AsyncSequence {
            typealias Element = Int

            let amount: Int

            /// `AsyncSequence` で定義されている実装が必要な型.
            struct AsyncIterator: AsyncIteratorProtocol {
                var amount: Int

                /// `AsyncIteratorProtocol` で実装が必要なメソッド.
                /// `nil` を返すことで `for await in` のループを終了させることができる.
                mutating func next() async -> Element? {
                    // 0 未満の場合は nil を返してループを抜ける.
                    guard amount >= 0 else { return nil }

                    // ?
                    let result = amount
                    amount -= 1
                    return result
                }
            }

            /// `AsyncSequence` で定義されている実装が必要なメソッド.
            func makeAsyncIterator() -> AsyncIterator {
                AsyncIterator(amount: amount)
            }
        }

        func countdown(amount: Int) -> AsyncCounter {
            AsyncCounter(amount: amount)
        }
    }
}

let counter = DefineCustomAsyncSequence.Counter()

Task {
    for await count in counter.countdown(amount: 10) {
        print(count)
    }

    let firstEven = await counter.countdown(amount: 10)
        .first(where: { $0 % 2 == 0 })
    print(firstEven as Any)
}

//: [Next](@next)
