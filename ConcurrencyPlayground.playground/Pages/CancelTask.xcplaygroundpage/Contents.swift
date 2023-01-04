//: [Previous](@previous)

import UIKit

// MARK: - 協調的な Task のキャンセル

/// `Task.checkCancellation` を利用したキャンセルのハンドリング.
///
/// `Task.checkCancellation` で現在のタスクがキャンセルマークが付けられているかどうかを確認することができる.
/// 現在のタスクにキャンセルマークが付けられた場合には `CancellationError` をスローして、そのタスクが実際にキャンセルされてタスクの処理が完了する.
///
/// なので、長時間かかる計算処理の前にこのメソッドを呼び出しておくことで、計算前にタスクがキャンセルされた場合に速やかにタスクを完了させることができる.
func fetchDataWithLongTask() async throws -> [String] {
    await withThrowingTaskGroup(of: [String].self) { group in
        group.addTask {
            // キャンセルをチェックしておく.
            // タスクがキャンセルとしてマークされていたらこのタスクもキャンセルする.
            try Task.checkCancellation()

            // キャンセルの確認後に長い処理.
            await longTask()
            return ["a", "b"]
        }

        // 明示的にキャンセルを行う.
        // 本来これだけでは子タスクはキャンセルされない.
        group.cancelAll()
        return []
    }
}

/// `Task.isCancelled` を利用したキャンセルのハンドリング.
///
/// `Task.isCancelled` は現在のタスクがキャンセルされたものとしてマークされているかどうかを確認できる.
/// こっちは例外を投げないので、独自にキャンセル処理をしたい場合に利用できる.
///
/// 例えば、画像一覧を取得するような処理でキャンセル時には途中まで取得できた画像をリターンしたい場合など.
func fetchIconsWithLongTask(for ids: [String]) async throws -> [UIImage] {
    try await withThrowingTaskGroup(of: UIImage.self) { group in
        for id in ids {
            // もしキャンセルとしてマークされていたら途中でループを抜ける.
            guard !Task.isCancelled else { break }

            group.addTask {
                await fetchImage(with: id)
            }
        }

        var icons = [UIImage]()
        for try await image in group {
            // キャンセルされたらそこまで取得した画像を渡せる.
            icons.append(image)
        }
        return icons
    }
}

func fetchImage(with id: String) async -> UIImage {
    UIImage()
}

func longTask() async {
    try? await Task.sleep(nanoseconds: 2 * NSEC_PER_MSEC)
}

// MARK: キャンセルチェックの有無と実行時間について

enum TimeTracker {
    static func track(_ process: (() async -> Void)) async {
        let start = Date()
        await process()
        let end = Date()
        let interval = end.timeIntervalSince(start)
        let formatted = String(format: "%.2f", interval)
        print("\(formatted) 秒経過")
    }
}

func showNonHandlingCancel() {
    Task {
        await TimeTracker.track {
            await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    // エラーが発生しても実際はキャンセルされない `Task.sleep(_:)` を利用する.
                    await Task.sleep(NSEC_PER_SEC * 3)
                }
                // 親タスクをここでキャンセルしても子タスクの処理は続くので結局 3 秒かかってしまう.
                group.cancelAll()
            }
        }
    }
}

func showHandlingCancel() {
    Task {
        await TimeTracker.track {
            await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    // キャンセルされているかを確認して、キャンセルされていたらエラーを投げる.
                    try Task.checkCancellation()
                    await Task.sleep(NSEC_PER_SEC * 3)
                }
                // 親タスクがキャンセルされて、子タスクまで伝播して子タスク内でキャンセルが確認されて途中で処理が中断される.
                group.cancelAll()
            }
        }
    }
}

showHandlingCancel()
showNonHandlingCancel()

//: [Next](@next)
