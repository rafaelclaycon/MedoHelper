//
//  APIClient.swift
//  WatchMedoHelper Watch App
//
//  Created by Rafael Schmitt on 10/02/25.
//

import Foundation

final class APIClient {

    func getStatusCode(from url: URL) async throws -> Int {
        let (_, response) = try await URLSession.shared.data(from: url)
        guard let response = response as? HTTPURLResponse else {
            throw APIClientError.badResponse
        }
        return response.statusCode
    }
}

enum APIClientError: Error {

    case badResponse
}
