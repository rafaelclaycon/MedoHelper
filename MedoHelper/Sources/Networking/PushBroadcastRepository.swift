//
//  PushBroadcastRepository.swift
//  MedoHelper
//
//  Created by Claude on 25/10/26.
//

import Foundation

protocol PushBroadcastRepositoryProtocol {

    /// Devices a broadcast would reach right now.
    func audience() async throws -> Int
    /// Newest first. The server only remembers broadcasts since its last restart.
    func broadcasts() async throws -> [PushBroadcastStatus]
    func broadcast(id: UUID) async throws -> PushBroadcastStatus
    /// Returns as soon as the server starts sending; poll `broadcast(id:)` for progress.
    func send(_ request: PushBroadcastRequest) async throws -> PushBroadcastStatus
    func cancel(id: UUID) async throws -> PushBroadcastStatus
}

enum PushBroadcastError: LocalizedError {

    case missingPassword
    case wrongPassword
    case alreadySending
    case server(statusCode: Int, reason: String?)

    var errorDescription: String? {
        switch self {
        case .missingPassword:
            return "Falta SEND_NOTIFICATION_PASSWORD no Secrets.xcconfig."
        case .wrongPassword:
            return "O servidor recusou a senha de notificações."
        case .alreadySending:
            return "Já tem um envio em andamento. Espere terminar ou cancele."
        case .server(let statusCode, let reason):
            return reason.map { "Erro \(statusCode): \($0)" } ?? "Erro \(statusCode) do servidor."
        }
    }
}

/// Talks to the push broadcast endpoints, all protected by the send notification password.
///
/// - `GET  {serverPath}v4/push-audience/{password}`              → `PushAudience`
/// - `POST {serverPath}v4/push-broadcasts/{password}`            → `PushBroadcastStatus`
/// - `GET  {serverPath}v4/push-broadcasts/{password}`            → `[PushBroadcastStatus]`
/// - `GET  {serverPath}v4/push-broadcast/{id}/{password}`        → `PushBroadcastStatus`
/// - `POST {serverPath}v4/push-broadcast/{id}/cancel/{password}` → `PushBroadcastStatus`
final class PushBroadcastRepository: PushBroadcastRepositoryProtocol {

    func audience() async throws -> Int {
        let audience: PushAudience = try await request("GET", path: "v4/push-audience")
        return audience.deviceCount
    }

    func broadcasts() async throws -> [PushBroadcastStatus] {
        try await request("GET", path: "v4/push-broadcasts")
    }

    func broadcast(id: UUID) async throws -> PushBroadcastStatus {
        try await request("GET", path: "v4/push-broadcast/\(id.uuidString)")
    }

    func send(_ request: PushBroadcastRequest) async throws -> PushBroadcastStatus {
        try await self.request("POST", path: "v4/push-broadcasts", body: request)
    }

    func cancel(id: UUID) async throws -> PushBroadcastStatus {
        try await request("POST", path: "v4/push-broadcast/\(id.uuidString)/cancel")
    }

    // MARK: - Private

    private struct ErrorBody: Decodable {
        let reason: String
    }

    private func request<T: Decodable>(_ method: String, path: String, body: (some Encodable)? = nil as String?) async throws -> T {
        guard let password = Secrets.sendNotificationPassword else {
            throw PushBroadcastError.missingPassword
        }

        var request = URLRequest(url: URL(string: serverPath + path + "/\(password)")!)
        request.httpMethod = method
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.badResponse
        }
        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw PushBroadcastError.wrongPassword
        case 409:
            throw PushBroadcastError.alreadySending
        default:
            let reason = try? JSONDecoder().decode(ErrorBody.self, from: data).reason
            throw PushBroadcastError.server(statusCode: httpResponse.statusCode, reason: reason)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }
}
