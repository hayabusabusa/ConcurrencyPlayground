//
//  APIClient.swift
//  ConcurrencyPlayground
//
//  Created by Shunya Yamada on 2023/01/06.
//

import Foundation

enum APIClientError: Error {
    case invalidURL
    case responseError
    case parseError(Error)
    case serverError(Error)
    case basStatus(statusCode: Int)
    case unknownServerStatus
    case noData
}

final class APIClient {
    private let session: URLSession
    private var baseURLString: String {
        "https://api.github.com"
    }

    init(session: URLSession) {
        self.session = session
    }

    func request<Request>(with request: Request,
                          completion: @escaping (Result<Request.Response?, APIClientError>) -> Void) where Request: RequestType {
        guard let urlRequest = request.makeURLRequest(for: baseURLString) else {
            completion(.failure(.invalidURL))
            return
        }

        requestData(with: urlRequest) { result in
            do {
                guard let data = try result.get() else {
                    completion(.success(nil))
                    return
                }

                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let decoded = try decoder.decode(Request.Response.self, from: data)
                completion(.success(decoded))
            } catch {
                completion(.failure(error as? APIClientError ?? .responseError))
            }
        }
    }

    func requestData(with urlRequest: URLRequest,
                     completion: @escaping (Result<Data?, APIClientError>) -> Void) {
        let task = session.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                completion(.failure(.serverError(error)))
            } else {
                guard let httpStatus = response as? HTTPURLResponse else {
                    completion(.failure(.responseError))
                    return
                }

                switch httpStatus.statusCode {
                case 200 ..< 400:
                    completion(.success(data))
                case 400... :
                    completion(.failure(.basStatus(statusCode: httpStatus.statusCode)))
                default:
                    completion(.failure(.unknownServerStatus))
                }
            }
        }
        task.resume()
    }
}
