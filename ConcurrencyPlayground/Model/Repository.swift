//
//  Repository.swift
//  ConcurrencyPlayground
//
//  Created by Shunya Yamada on 2023/01/06.
//

import Foundation

struct Repository: Decodable, Hashable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let stargazersCount: Int
    let language: String?
    let htmlUrl: String
    let owner: Owner
}

extension Repository {
    struct Owner: Decodable, Hashable, Identifiable {
        let id: Int
        let avatarURL: String

        private enum CodingKeys: String, CodingKey {
            case id
            case avatarURL = "avatarUrl"
        }
    }
}
