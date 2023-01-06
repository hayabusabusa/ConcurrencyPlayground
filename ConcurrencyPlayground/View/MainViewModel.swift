//
//  MainViewModel.swift
//  ConcurrencyPlayground
//
//  Created by Shunya Yamada on 2023/01/06.
//

import UIKit

@MainActor
final class MainViewModel {
    typealias SnapshotType = NSDiffableDataSourceSnapshot<MainViewController.Section, MainViewController.Item>

    private let apiClient: APIClient
    var updateSnapshot: (SnapshotType) -> Void = { _ in }
    var showError: (APIClientError) -> Void = { _ in }

    init(apiClient: APIClient = APIClient(session: .shared)) {
        self.apiClient = apiClient
    }

    func fetchData() {
//        let request = SearchRepositoryRequest(query: "swift")
//        apiClient.request(with: request) { [weak self] result in
//            guard let self = self else { return }
//            switch result {
//            case .success(let response):
//                guard let response = response else {
//                    self.showError(.noData)
//                    return
//                }
//                let snapshot = self.makeSnapshot(from: response.items)
//                self.updateSnapshot(snapshot)
//            case .failure(let error):
//                self.showError(error)
//            }
//        }
        Task {
            let snapshot = try await fetchDataByConcurrency()
            updateSnapshot(snapshot)
        }
    }

    func fetchImage(for item: MainViewController.Item,
                    completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: item.repository.owner.avatarURL) else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataDontLoad
        apiClient.requestData(with: request) { result in
            switch result {
            case .success(let data):
                guard let data = data else {
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }
                let image = UIImage(data: data)
                DispatchQueue.main.async {
                    completion(image)
                }
            case .failure:
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}

private extension MainViewModel {
    /// データ取得の Concurrency 対応版.
    ///
    /// `@MainActor` がついているので、全てのメソッドがメインスレッドで実行されてしまうが、
    /// データの取得をメインスレッドで実行したくないので `nonisolated` をつける.
    nonisolated
    func fetchDataByConcurrency() async throws -> SnapshotType {
        let request = SearchRepositoryRequest(query: "swift")
        do {
            // Concurrency 対応版のメソッドを利用する.
            let response = try await apiClient.request(with: request)

            guard let response = response else { throw APIClientError.noData }
            // `makeSnapshot(from:)` は MainActor の Actor 隔離に守られているので `nonisolated` のメソッドから実行するために `await` をつける.
            return await makeSnapshot(from: response.items)
        }
    }

    func makeSnapshot(from repositories: [Repository]) -> SnapshotType {
        let items = repositories.map { MainViewController.Item(repository: $0, image: nil) }
        var snapshot = SnapshotType()
        snapshot.appendSections([.main])
        snapshot.appendItems(items)
        return snapshot
    }
}
