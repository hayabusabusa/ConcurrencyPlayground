//
//  ResponseType.swift
//  ConcurrencyPlayground
//
//  Created by Shunya Yamada on 2023/01/06.
//

import Foundation

struct SearchRepositoryResponse: Decodable {
    public let totalCount: Int
    public let items: [Repository]
}
