//: [Previous](@previous)

import SwiftUI
import UIKit

// MARK: - 2 データ競合を守る新しい型 Actor

// マルチスレッドプログラミングにおいて、データ競合をいかに防ぐかが重要.
// 複数のスレッドから一つのデータにアクセスした場合、データが不整合を起こしてしまう可能性がある.

final class Score {
    var logs = [Int]()
    private(set) var highScore: Int = 0

    func update(with score: Int) {
        logs.append(score)
        if score > highScore {
            highScore = score
        }
    }
}

// 100 の後に 110 が表示されるはずが、どちらも 110 になったり 100 になったりする.
let score = Score()
DispatchQueue.global(qos: .default).async {
    score.update(with: 100)
    print(score.highScore)
}

DispatchQueue.global(qos: .default).async {
    score.update(with: 110)
    print(score.highScore)
}

/// データ競合を防ぐために `DispatchQueue` のシリアルキューを利用する.
///
/// 他にもスレッドのロックなどで防いだりできるが、ロックは扱いが難しい.
enum UseSerialDispatchQueue {
    final class Score {
        private let serialQueue = DispatchQueue(label: "serial-dispatch-queue")

        var logs = [Int]()
        private(set) var highScore: Int = 0

        func update(with score: Int, completion: @escaping ((Int) -> Void)) {
            // シリアルキューはキューに入れられたタスクを順に実行して、1度にひとつのタスクしか実行されない.
            // これでプロパティ更新中に他の処理が実行されるのを防ぐ.
            serialQueue.async { [weak self] in
                guard let self = self else { return }

                self.logs.append(score)
                if score > self.highScore {
                    self.highScore = score
                }

                completion(self.highScore)
            }
        }
    }
}

let serialScore = UseSerialDispatchQueue.Score()
// 複数スレッドで実行されても期待通り 100 の後に 110 が表示される.
// ただ、シリアルキューで保護することができるが、ボイラープレートが多くなってしまう.
DispatchQueue.global(qos: .default).async {
    serialScore.update(with: 100) { highScore in
        print(highScore)
    }
}

DispatchQueue.global(qos: .default).async {
    serialScore.update(with: 110) { highScore in
        print(highScore)
    }
}

/// 新しく追加された `Actor` を利用してデータ競合を守る.
///
/// `Actor` で作られたインスタンスは同時に一つの処理のみでアクセスされるようになる.( Actor 隔離 )
enum UseActor {
    // class を actor に変えるだけ.
    actor Score {
        var logs = [Int]()
        private(set) var highScore: Int = 0

        func update(with score: Int) {
            logs.append(score)
            if score > highScore {
                highScore = score
            }
        }
    }
}

let actorScore = UseActor.Score()
// Actor のメソッドやプロパティにアクセスするためには await が必要.
Task.detached {
    await actorScore.update(with: 100)
    print(await actorScore.highScore)
}

Task.detached {
    await actorScore.update(with: 110)
    print(await actorScore.highScore)
}

/// `nonisolated` で Actor 隔離を解除する.
///
/// `Actor` で処理を隔離すると、アクセスには await が必要になる.
/// それでは都合が悪い場合があり、例えば `Hashable` プロトコルに準拠させるとエラーになる.
enum UseNonisolated {
    actor B: Hashable {
        let id = UUID()
        private(set) var number = 0

        static func == (lhs: UseNonisolated.B, rhs: UseNonisolated.B) -> Bool {
            lhs.id == rhs.id
        }

        // ここでエラーになるので nonisolated で回避する.
        // Actor-isolated instance method 'hash(into:)' cannot be used to satisfy nonisolated protocol requirement
        nonisolated func hash(into hasher: inout Hasher) {
            // Actor 隔離が解除されて await なしで実行できる.
            hasher.combine(id)
            // ただし、書き込み可能なデータやその操作に対して、nonisolated をつけることはできない.
            // なぜなら書き込みできるデータはデータ競合が起きる可能性があるため、コンパイラが守っている.
//            hasher.combine(number)
        }

        func increase() {
            number += 1
        }
    }
}

/// Actor のもつ再入可能性について.
///
/// await でプログラムが中断しても他の関数を呼び出すことができる.
/// デッドロックの発生を回避することができるが、競合状態が発生する可能性がある.
enum ActorReentrancy {
    actor Score {
        var localLogs = [Int]()
        private(set) var highScore: Int = 0

        func update(with score: Int) async {
//            localLogs.append(score)
            // ここで処理が中断されるが、そのまま次の実行は進んでしまうため上の append はどんどん実行されてしまう.
            highScore = await requestHighScore(with: score)
            // append を後にすると結果が変わる.
            // このように await の前後でプロパティの状態が変化する.
            localLogs.append(score)
        }

        /// サーバーに点数を送って最高得点を取得するとする.
        func requestHighScore(with score: Int) async -> Int {
            try? await Task.sleep(nanoseconds: 500000)
            return score
        }
    }

    actor ImageDownloader {
        private var cached = [String: UIImage]()

        func image(from url: String) async -> UIImage {
            if let cachedImage = cached[url] {
                return cachedImage
            }

            // ここで中断されるが、次の実行は待たない.
            // その結果毎回キャッシュがない扱いになって、常にサーバー側にリクエストしてしまう可能性がある.
            let image = await downloadImage(from: url)

            // 対策として、再度キャッシュを確認用にする.
            // ただこれコードの意味が分かりづらいし、結局サーバーへのリクエストが発生している.
            if !cached.keys.contains(url) {
                cached[url] = image
            }

            return cached[url]!
        }

        /// サーバーに画像をリクエストする.
        func downloadImage(from url: String) async -> UIImage {
            try? await Task.sleep(nanoseconds: 500000)
            switch url {
            case "car":
                // サーバー側でリソースが変わったことを想定.
                let name = Bool.random() ? "car" : "bus"
                return UIImage(systemName: name)!
            default:
                return UIImage()
            }
        }
    }

    actor TaskedImageDownloader {
        private enum CacheEntry {
            case progress(Task<UIImage, Never>)
            case ready(UIImage)
        }

        private var cache = [String: CacheEntry]()

        func image(from url: String) async -> UIImage {
            if let cached = cache[url] {
                switch cached {
                case .ready(let image):
                    return image
                case .progress(let task):
                    // 処理中なら task.value で画像を取得、await があるのでプログラムは中断される.
                    return await task.value
                }
            }

            let task = Task {
                // 非同期で画像を取得して返す.
                await downloadImage(from: url)
            }

            // 処理中で保存しておく.
            cache[url] = .progress(task)

            // ここで画像を取得、await があるため処理が中断される.
            let image = await task.value
            cache[url] = .ready(image)
            return image
        }

        /// サーバーに画像をリクエストする.
        func downloadImage(from url: String) async -> UIImage {
            try? await Task.sleep(nanoseconds: 500000)
            switch url {
            case "car":
                // サーバー側でリソースが変わったことを想定.
                let name = Bool.random() ? "car" : "bus"
                return UIImage(systemName: name)!
            default:
                return UIImage()
            }
        }
    }
}

let reentrancyScore = ActorReentrancy.Score()
Task.detached {
    await reentrancyScore.update(with: 100)
    print(await reentrancyScore.localLogs)
    print(await reentrancyScore.highScore)
}

Task.detached {
    await reentrancyScore.update(with: 110)
    print(await reentrancyScore.localLogs)
    print(await reentrancyScore.highScore)
}

let imageDownloader = ActorReentrancy.ImageDownloader()
// 並列だと期待しない結果になる、順列だと期待通りになる.
Task.detached {
    let image = await imageDownloader.image(from: "car")
    print(image)
}

Task.detached {
    let image = await imageDownloader.image(from: "car")
    print(image)
}

/// UI 操作のコードにもデータ競合が発生しないようにする専用の `MainActor`.
///
/// `MainActor` を適応するとグローバルに共通な Actor インスタンスが作成される.
/// そのインスタンスを通して Actor 隔離が行われる.
/// 内部で `DispatchQueue.main` を呼び出しているので処理がメインスレッドで実行されることを保証している.
enum UseMainActor {
    @MainActor
    final class UserDataSource {
        // 暗黙的に MainActor が適応されている.
        var user = ""

        // 暗黙的に MainActor が適応されている.
        func updateUser() {
            // do something
        }

        // nonisolated で MainActor を解除する.
        nonisolated func sendLogs() {
            // do something
        }
    }

    @MainActor
    final class ViewModel: ObservableObject {
        // 暗黙的に MainActor が適応されている.
        @Published private(set) var text = ""

        /// サーバーからユーザーを取得することを想定.
        ///
        /// サーバー通信はメインスレッドで実行するべきではないので nonisolated をつける.
        nonisolated func fetchUser() async -> String {
            // ただ、nonisolated のメソッド内でプロパティは更新できない.
            // なので nonisolated であるメソッドでは値を返すように実装する.
            return await waitOneSecond(with: "arex")
        }

        func didTapButton() {
            Task {
                text = ""
                // 別のメソッドで text を更新.
                text = await fetchUser()
            }
        }

        private func waitOneSecond(with string: String) async -> String {
            try? await Task.sleep(nanoseconds: 500000)
            return string
        }
    }
}

//: [Next](@next)
