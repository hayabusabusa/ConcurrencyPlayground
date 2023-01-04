//: [Previous](@previous)

import Foundation

// MARK: - Async let バインディング

struct MyPageInfo {
    let friends: [String]
    let articles: [String]
}

enum API {
    static func fetchFriends() async -> [String] {
        try? await Task.sleep(nanoseconds: NSEC_PER_MSEC * 1)
        return ["A", "B", "C"]
    }

    static func fetchArticles() async -> [String] {
        try? await Task.sleep(nanoseconds: NSEC_PER_MSEC * 3)
        return ["X", "Y", "Z"]
    }
}

enum DB {
    static func fetchFriends() async throws -> [String] {
        try await Task.sleep(nanoseconds: NSEC_PER_MSEC * 2)
        return ["D", "E"]
    }
}

/// `TaskGroup` の例を `async let` を利用して書き直す.
func fetchMyPageData() async -> MyPageInfo {
    // `async let` で変数を定義すると自動的に子タスクとして実行される.
    async let friends = API.fetchFriends()
    async let articles = API.fetchArticles()
    // 変数を利用する前に await で子タスクの結果を待つ.
    // これは group インスタンスに for await でループを回していたのと同じ操作.
    return await MyPageInfo(friends: friends, articles: articles)
}

/// エラーが発生する場合の `async let` バインディング.
func fetchAllFriends() async throws -> [String] {
    async let friends = API.fetchFriends()
    async let localFriends = DB.fetchFriends()
    // エラーを投げる非同期処理の場合は `try await` をつける.
    // このままだと `DB.fetchFriends()` の処理分時間がかかるので、`async let` でもキャンセルをハンドリングしておいた方が良い.
    // また、`await` が付けられた順で非同期の結果を待ち受ける.
    return try await friends + localFriends
}

/// `async let` した変数を `await` で利用しなかった場合.
func noMarkAwait() {
    Task {
        async let friends = API.fetchFriends()
        async let articles = API.fetchArticles()
        // 変数を `await` しない場合はすぐにリターンされる.
        // この場合は関数のスコープを抜けた段階で子タスクがキャンセルとしてマークされる.
    }
}

//: [Next](@next)
