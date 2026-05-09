//
//  SoundRequestsRepository.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 19/04/26.
//

import Foundation

// MARK: - Protocol

protocol SoundRequestsRepositoryProtocol {

    func allRequests() async throws -> [SoundRequest]
    func add(_ request: SoundRequest) async throws
    func update(_ request: SoundRequest) async throws
    func remove(withId id: String) async throws
}

// MARK: - Concrete

/// Server-backed repository for user sound requests.
///
/// The backend endpoint is **not yet implemented**. Each method throws
/// `SoundRequestsRepositoryError.notImplemented`, so the `ViewModel` falls
/// back to its in-memory list and the UI remains usable today.
///
/// Expected endpoints (to wire up on `medo-delirio-api`):
/// - `GET    {serverPath}v1/sound-requests/{password}`            → `[SoundRequest]`
/// - `POST   {serverPath}v1/sound-request/{password}`             body: `SoundRequest`
/// - `PUT    {serverPath}v1/sound-request/{password}`             body: `SoundRequest`
/// - `DELETE {serverPath}v1/sound-request/{id}/{password}`
final class SoundRequestsRepository: SoundRequestsRepositoryProtocol {

    private let apiClient: APIClient

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    func allRequests() async throws -> [SoundRequest] {
        throw SoundRequestsRepositoryError.notImplemented
    }

    func add(_ request: SoundRequest) async throws {
        throw SoundRequestsRepositoryError.notImplemented
    }

    func update(_ request: SoundRequest) async throws {
        throw SoundRequestsRepositoryError.notImplemented
    }

    func remove(withId id: String) async throws {
        throw SoundRequestsRepositoryError.notImplemented
    }
}

// MARK: - JSON-File Fallback

/// Local, file-backed repository used while the server endpoint is still
/// being built. Everything lives in a single JSON file under
/// `~/Library/Application Support/MedoHelper/SoundRequests.json`, so the
/// list survives app restarts.
///
/// Mutations rewrite the entire file atomically; this is deliberate — the
/// data set is tiny (dozens of entries at most) and rewriting avoids any
/// merge/concurrency gotchas until the server takes over.
final class JSONSoundRequestsRepository: SoundRequestsRepositoryProtocol {

    private let fileURL: URL
    private let ioQueue = DispatchQueue(label: "medohelper.sound-requests.json", qos: .userInitiated)

    /// - Parameter fileURL: override the JSON location (useful for tests).
    ///   Defaults to `Application Support/MedoHelper/SoundRequests.json`.
    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            self.fileURL = Self.defaultFileURL()
        }
        ensureParentDirectoryExists()
    }

    func allRequests() async throws -> [SoundRequest] {
        try readAll()
    }

    func add(_ request: SoundRequest) async throws {
        var current = (try? readAll()) ?? []
        if let existingIndex = current.firstIndex(where: { $0.id == request.id }) {
            current[existingIndex] = request
        } else {
            current.append(request)
        }
        try writeAll(current)
    }

    func update(_ request: SoundRequest) async throws {
        var current = try readAll()
        guard let index = current.firstIndex(where: { $0.id == request.id }) else {
            throw SoundRequestsRepositoryError.notFound(request.id)
        }
        current[index] = request
        try writeAll(current)
    }

    func remove(withId id: String) async throws {
        var current = try readAll()
        let before = current.count
        current.removeAll { $0.id == id }
        guard current.count < before else {
            throw SoundRequestsRepositoryError.notFound(id)
        }
        try writeAll(current)
    }

    // MARK: - Private

    private static func defaultFileURL() -> URL {
        let base: URL
        do {
            base = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        } catch {
            // Last-ditch fallback; `url(for:)` only throws in genuinely broken environments.
            base = FileManager.default.temporaryDirectory
        }
        return base
            .appendingPathComponent("MedoHelper", isDirectory: true)
            .appendingPathComponent("SoundRequests.json", isDirectory: false)
    }

    private func ensureParentDirectoryExists() {
        let parent = fileURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: parent.path) {
            try? FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        }
    }

    private func readAll() throws -> [SoundRequest] {
        try ioQueue.sync {
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
            let data = try Data(contentsOf: fileURL)
            guard !data.isEmpty else { return [] }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([SoundRequest].self, from: data)
        }
    }

    private func writeAll(_ requests: [SoundRequest]) throws {
        try ioQueue.sync {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(requests)
            try data.write(to: fileURL, options: .atomic)
        }
    }
}

// MARK: - Errors

enum SoundRequestsRepositoryError: Error, LocalizedError {

    case notImplemented
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Endpoint de pedidos ainda não disponível no servidor."
        case .notFound(let id):
            return "Pedido com ID \(id) não encontrado."
        }
    }
}
