//
//  DynamicBannerRepository.swift
//  MedoHelper
//
//  Created by Claude on 25/10/26.
//

import Foundation

protocol DynamicBannerRepositoryProtocol {

    /// The banner on the server, or nil when none was ever set or it was removed.
    func banner() async throws -> DynamicBannerData?
    func setBanner(_ banner: DynamicBannerData) async throws
    /// Takes the banner out of the app.
    func removeBanner() async throws
}

enum DynamicBannerError: LocalizedError {

    case missingPassword
    case wrongPassword
    case server(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .missingPassword:
            return "Falta DYNAMIC_BANNER_PASSWORD no Secrets.xcconfig."
        case .wrongPassword:
            return "O servidor recusou a senha do banner."
        case .server(let statusCode):
            return "Erro \(statusCode) do servidor."
        }
    }
}

/// Talks to the `dynamic-banner` endpoints. The server stores the banner as an opaque
/// string, so the JSON goes both ways as plain text.
///
/// There's no delete: removing means storing `{}`, which the app fails to decode and so
/// shows no banner. The server refuses an empty string, so `{}` is the way.
///
/// - `GET  {serverPath}v4/dynamic-banner`                       → banner JSON, `{}` once removed, 404 if never set
/// - `POST {serverPath}v4/dynamic-banner/{dynamicBannerPassword}` body: banner JSON or `{}`
final class DynamicBannerRepository: DynamicBannerRepositoryProtocol {

    func banner() async throws -> DynamicBannerData? {
        let url = URL(string: serverPath + "v4/dynamic-banner")!
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.badResponse
        }
        switch httpResponse.statusCode {
        case 200...299:
            if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any], object.isEmpty {
                return nil
            }
            return try JSONDecoder().decode(DynamicBannerData.self, from: data)
        case 404:
            return nil
        default:
            throw DynamicBannerError.server(statusCode: httpResponse.statusCode)
        }
    }

    func setBanner(_ banner: DynamicBannerData) async throws {
        try await post(try Self.encoded(banner))
    }

    func removeBanner() async throws {
        try await post(Data("{}".utf8))
    }

    /// Pretty-printed with sorted keys, so whoever reads the setting on the server can
    /// still follow it and the same banner always comes out the same.
    static func encoded(_ banner: DynamicBannerData) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(banner)
    }

    // MARK: - Private

    private func post(_ body: Data) async throws {
        guard let password = Secrets.dynamicBannerPassword else {
            throw DynamicBannerError.missingPassword
        }
        let url = URL(string: serverPath + "v4/dynamic-banner/\(password)")!

        // The endpoint decodes the body as a String, so it must go as text/plain; as
        // application/json Vapor would try to read the object itself as a String.
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.badResponse
        }
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 403:
            throw DynamicBannerError.wrongPassword
        default:
            throw DynamicBannerError.server(statusCode: httpResponse.statusCode)
        }
    }
}
