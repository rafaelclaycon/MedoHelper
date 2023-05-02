//
//  NetworkRabbit.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 02/05/23.
//

import Foundation

class NetworkRabbit {
    
    static func post<T: Codable>(data: T, to url: URL) async throws {
        // Create the URL request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode the data as JSON
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(data)
        print(jsonData)
        request.httpBody = jsonData
        
        // Send the request using URLSession
        let session = URLSession.shared
        let (data, response) = try await session.data(for: request)
        
        // Check for a successful response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.badResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            print(httpResponse.statusCode)
            throw NetworkError.badResponse
        }
        
        // Handle the response data (if needed)
        print(String(data: data, encoding: .utf8) ?? "")
    }
    
    static func test<T: Codable>(data: T) {
        let encoder = JSONEncoder()
        let jsonData = try! encoder.encode(data)
        
        let decoder = JSONDecoder()
        let authors = try! decoder.decode([Author].self, from: jsonData)
        print(authors)
    }
}

enum NetworkError: Error {
    
    case badResponse
}