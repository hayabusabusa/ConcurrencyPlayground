//: [Previous](@previous)

import UIKit

// MARK: - Structured Concurrency の 1 つであるタスクグループを利用した並列処理

/// マイページ画面に表示するデータ.
///
/// 2 つの API の情報をまとめる必要がある.
struct MyPage {
    let friends: [String]
    let articleTitles: [String]
}

private enum Util {
    static func wait(seconds: UInt64) async {
        try? await Task.sleep(nanoseconds: seconds * NSEC_PER_SEC)
    }
}

func fetchFriends() async -> [String] {
    await Util.wait(seconds: 3)
    return [
        "A",
        "B",
        "C"
    ]
}

func fetchArticles() async -> [String] {
    await Util.wait(seconds: 1)
    return [
        "X",
        "Y",
        "Z"
    ]
}

func fetchFriendsFromLocalDB() async throws -> [String] {
    await Util.wait(seconds: 2)
    return [
        "α",
        "β",
        "γ"
    ]
}

/// エラーを投げない TaskGroup を利用して 2 つの API の結果を並列処理でまとめる.
func fetchMyPageData() async -> MyPage {
    /// TaskGroup ではリターンする型を揃える必要があるので enum で定義する
    enum _FetchType {
        case friends([String])
        case articles([String])
    }

    var friends = [String]()
    var articles = [String]()

    // 引数の `of` には子タスク実行時にリターンする型を渡す必要がある.
    await withTaskGroup(of: _FetchType.self) { group in
        // 子タスクを追加、addTask が呼び出されるとすぐにクロージャーないの処理が実行される.
        // addTask のクロージャーは `@escaping` でキャプチャされるので `self` には注意する.
        group.addTask {
            let friends = await fetchFriends()
            return .friends(friends)
        }

        // 子タスクを追加.
        group.addTask {
            let articles = await fetchArticles()
            return .articles(articles)
        }

        // 追加した子タスクは並列で実行される.
        // 親子関係は以下のようになる.
        //
        // fetchMyPageData - group.addTask( fetchFriends )
        //                 - group.addTask( fetchArticles )

        // 子タスクの結果を取得.
        for await result in group {
            switch result {
            case .friends(let f):
                friends = f
            case .articles(let a):
                articles = a
            }
        }
    }

    // `next()` メソッドを使うことで 1 つずつ結果を取り出すことができる
    await withTaskGroup(of: _FetchType.self) { group in
        func _setValue(for result: _FetchType) {
            switch result {
            case .friends(let f):
                friends = f
            case .articles(let a):
                articles = a
            }
        }

        group.addTask {
            let friends = await fetchFriends()
            return .friends(friends)
        }

        group.addTask {
            let articles = await fetchArticles()
            return .articles(articles)
        }

        // 上記 2 つのタスクの内最初に終わった方の結果を取り出す.
        guard let first = await group.next() else {
            group.cancelAll()
            return
        }

        // `next()` を使うことで特定の条件の時は途中でキャンセルするとかもできる.
        // ただし、親タスク側で cancel するだけだと子タスクの処理は続いてしまうので注意.
        if case .friends(let f) = first, f.isEmpty {
            group.cancelAll()
        }
    }

    return MyPage(friends: friends,
                  articleTitles: articles)
}

/// TaskGroup を使って動的に並列処理を実行する.
func fetchFriendsAvatars(for ids: [String]) async -> [String: UIImage?] {
    @Sendable
    func _fetchAvatarImage(for id: String) async -> UIImage? {
        UIImage(systemName: "trim")
    }

    // 子タスクの方は `(String, UIImage?)` のタプルになる.
    return await withTaskGroup(of: (String, UIImage?).self) { group in
        // ID の分だけ子タスクを追加していく.
        ids.forEach { id in
            group.addTask {
                return (id, await _fetchAvatarImage(for: id))
            }
        }

        var avatars = [String: UIImage?]()
        for await (id, image) in group {
            avatars[id] = image
        }

        return avatars
    }
}

/// 子タスクでエラーが発生する場合は `withThrowingTaskGroup` を使う.
func fetchAllFriends() async throws -> [String] {
    return try await withThrowingTaskGroup(of: [String].self) { group in
        group.addTask {
            // 3 秒かかる処理だが、途中でエラーが発生したらここの処理もキャンセルされる.
            await fetchFriends()
        }

        group.addTask {
            // ここでエラーが発生した場合は親タスクにエラーが伝番される.
            try await fetchFriendsFromLocalDB()
        }

        var allFriends = [String]()
        for try await friends in group {
            allFriends.append(contentsOf: friends)
        }

        return allFriends
    }
}

//: [Next](@next)
