//
//  APIClient.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 02/05/23.
//

import Foundation

protocol APIClientProtocol {

    func `get`<T: Codable>(from url: URL) async throws -> T
    func `getArray`<T: Codable>(from url: URL) async throws -> [T]
    func getStatusCode(from url: URL) async throws -> Int

    func post<T: Codable>(data: T?, to url: URL) async throws -> String?
    func post<T: Encodable, U: Decodable>(data: T?, to url: URL) async throws -> U?
    func post(to url: URL) async throws -> Bool

    func put<T: Encodable>(in url: URL, data: T?) async throws -> Bool

    func delete(in url: URL) async throws -> Bool
    func delete<T: Encodable>(in url: URL, data: T?) async throws -> Bool
}

final class APIClient: APIClientProtocol {

    func `get`<T: Codable>(from url: URL) async throws -> T {
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        return try decoder.decode(T.self, from: data)
    }
    
    func `getArray`<T: Codable>(from url: URL) async throws -> [T] {
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode([T].self, from: data)
    }
    
    func getStatusCode(from url: URL) async throws -> Int {
        let (_, response) = try await URLSession.shared.data(from: url)
        guard let response = response as? HTTPURLResponse else {
            throw APIClientError.badResponse
        }
        return response.statusCode
    }
    
    func post<T: Codable>(data: T?, to url: URL) async throws -> String? {
        // Create the URL request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let data = data {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(data)
            print(jsonData)
            request.httpBody = jsonData
        }
        
        // Send the request using URLSession
        let session = URLSession.shared
        let (data, response) = try await session.data(for: request)
        
        // Check for a successful response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.badResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            print(url.absoluteString + " - Response: \(httpResponse.statusCode)")
            throw APIClientError.badResponse
        }
        
        // Handle the response data (if needed)
        return String(data: data, encoding: .utf8)
    }

    func post<T: Encodable, U: Decodable>(data: T?, to url: URL) async throws -> U? {
        // Create the URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let data = data {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(data)
            request.httpBody = jsonData
        }

        // Send the request using URLSession
        let session = URLSession.shared
        let (data, response) = try await session.data(for: request)

        // Check for a successful response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.badResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            print(url.absoluteString + " - Response: \(httpResponse.statusCode)")
            throw APIClientError.badResponse
        }

        // Decode the response data
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedData = try decoder.decode(U.self, from: data)

        return decodedData
    }

    func post(to url: URL) async throws -> Bool {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let session = URLSession.shared
        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.badResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            print(url.absoluteString + " - Response: \(httpResponse.statusCode)")
            throw APIClientError.badResponse
        }

        return true
    }

    func put<T: Encodable>(in url: URL, data: T? = nil) async throws -> Bool {
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let data = data {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(data)
        }

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.badResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            print(httpResponse.statusCode)
            throw APIClientError.badResponse
        }

        return true
    }

    func delete(in url: URL) async throws -> Bool {
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.badResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            print(httpResponse.statusCode)
            throw APIClientError.badResponse
        }

        return true
    }

    func delete<T: Encodable>(in url: URL, data: T?) async throws -> Bool {
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let data = data {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(data)
        }

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.badResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            print(httpResponse.statusCode)
            throw APIClientError.badResponse
        }

        return true
    }
}

enum APIClientError: Error {

    case badResponse
}

extension APIClientError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .badResponse:
            return NSLocalizedString("400 Bad Request", comment: "")
        }
    }
}
