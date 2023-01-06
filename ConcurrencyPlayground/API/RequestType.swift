//
//  RequestType.swift
//  ConcurrencyPlayground
//
//  Created by Shunya Yamada on 2023/01/06.
//

import Foundation

protocol RequestType {
    associatedtype Response: Decodable
    var path: String { get }
    var queryItems: [URLQueryItem]? { get }
    func makeURLRequest(for url: String) -> URLRequest?
}

extension RequestType {
    func makeURLRequest(for url: String) -> URLRequest? {
        guard let baseURL = URL(string: path, relativeTo: URL(string: url)) else {
            return nil
        }

        guard let components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) else {
            return nil
        }

        var mutableComponents = components
        mutableComponents.queryItems = queryItems

        guard let fullURL = mutableComponents.url else {
            return nil
        }

        var request = URLRequest(url: fullURL)
        request.addValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.httpMethod = "GET"
        return request
    }
}

struct SearchRepositoryRequest: RequestType {
    typealias Response = SearchRepositoryResponse

    let query: String

    var path: String {
        "/search/repositories"
    }
    
    var queryItems: [URLQueryItem]? {
        return [
            .init(name: "q", value: query),
            .init(name: "order", value: "desc")
        ]
    }
}
