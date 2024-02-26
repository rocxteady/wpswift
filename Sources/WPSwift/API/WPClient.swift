//
//  APIClient.swift
//
//
//  Created by Ulaş Sancak on 1.10.2023.
//

import Foundation
import Combine
import Resting

enum NetworkError: LocalizedError {
    case urlMalformed
    case api
    case unknown

    var errorDescription: String? {
        switch self {
        case .urlMalformed:
            "URL is malformed."
        case .api:
            "API returned an unexpected response."
        case .unknown:
            "Unknown error."
        }
    }
}

public struct WPClient<RequestModel: Encodable, Response: Decodable> {
    private let restClient: RestClient
    private let requestConfig: RequestConfiguration

    init(_ configuration: WPClientConfiguration) throws {
        let clientConfiguration = RestClientConfiguration(sessionConfiguration: configuration.sessionConfiguration, jsonDecoder: .initialize())
        restClient = RestClient(configuration: clientConfiguration)
        switch configuration.parameterType {
        case .object(let dictionary):
            requestConfig = RequestConfiguration(
                urlString: try .initialize(with: configuration.endpoint),
                method: configuration.method,
                parameters: dictionary,
                headers: configuration.headers, encoding: configuration.encoding
            )
        case .model(let encodable):
            requestConfig = RequestConfiguration(
                urlString: try .initialize(with: configuration.endpoint),
                method: configuration.method,
                body: try JSONEncoder.initialize().encode(encodable),
                headers: configuration.headers, encoding: configuration.encoding
            )
        case .none:
            requestConfig = RequestConfiguration(
                urlString: try .initialize(with: configuration.endpoint),
                method: configuration.method,
                headers: configuration.headers, encoding: configuration.encoding
            )
            break
        }
    }

    func fetch() async throws -> Response {
        return try await restClient.fetch(with: requestConfig)
    }
}

extension WPClient {
    func fetchPublisher() -> AnyPublisher<Response, Error> {
        restClient.publisher(with: requestConfig)
    }
}
