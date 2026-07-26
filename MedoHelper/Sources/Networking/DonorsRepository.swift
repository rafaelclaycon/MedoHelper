//
//  DonorsRepository.swift
//  MedoHelper
//
//  Created by Claude on 03/07/26.
//

import Foundation

// MARK: - Server

protocol DonorsRepositoryProtocol {

    /// Current donors as stored on the server (no local add-dates).
    func serverDonors() async throws -> [DonorDTO]

    /// Replace the whole donor list on the server. `set-donor-names` is a
    /// full-replace ("set") operation, so the entire array is always sent.
    func setDonors(_ donors: [DonorDTO]) async throws
}

/// Talks to the `donor-names` / `set-donor-names` endpoints.
///
/// - `GET  {serverPath}v3/donor-names`                       → `[DonorDTO]`
/// - `POST {serverPath}v3/set-donor-names/{donorsPassword}`  body: `[DonorDTO]`
final class DonorsRepository: DonorsRepositoryProtocol {

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    func serverDonors() async throws -> [DonorDTO] {
        let url = URL(string: serverPath + "v3/donor-names")!
        return try await apiClient.getArray(from: url)
    }

    func setDonors(_ donors: [DonorDTO]) async throws {
        let url = URL(string: serverPath + "v3/set-donor-names/\(Secrets.donorsPassword)")!

        // The endpoint decodes the body as a plain-text String (the raw JSON)
        // and parses it itself, so we must NOT send `Content-Type: application/json`
        // — otherwise Vapor tries to JSON-decode the array into a String and
        // fails with "Expected to decode String but found an array". This mirrors
        // hitting it from Postman with a "raw" (text/plain) body.
        let jsonData = try JSONEncoder().encode(donors)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.badResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            print(url.absoluteString + " - Response: \(httpResponse.statusCode)")
            throw APIClientError.badResponse
        }
    }
}

// MARK: - Local Store

/// Local, file-backed store for the working donor list. Persists the full
/// `Donor` model — including the `createdAt` used for the "by add date" sort —
/// under `~/Library/Application Support/MedoHelper/Donors.json`, so edits and
/// add-dates survive app restarts even before they're sent to the server.
///
/// Mutations rewrite the whole file atomically; the data set is tiny, so this
/// keeps the code simple and avoids any merge/concurrency gotchas.
final class DonorsLocalStore {

    private let fileURL: URL
    private let ioQueue = DispatchQueue(label: "medohelper.donors.json", qos: .userInitiated)

    /// - Parameter fileURL: override the JSON location (useful for tests).
    init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultFileURL()
        ensureParentDirectoryExists()
    }

    func load() -> [Donor] {
        (try? readAll()) ?? []
    }

    func save(_ donors: [Donor]) {
        try? writeAll(donors)
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
            base = FileManager.default.temporaryDirectory
        }
        return base
            .appendingPathComponent("MedoHelper", isDirectory: true)
            .appendingPathComponent("Donors.json", isDirectory: false)
    }

    private func ensureParentDirectoryExists() {
        let parent = fileURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: parent.path) {
            try? FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        }
    }

    private func readAll() throws -> [Donor] {
        try ioQueue.sync {
            guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
            let data = try Data(contentsOf: fileURL)
            guard !data.isEmpty else { return [] }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Donor].self, from: data)
        }
    }

    private func writeAll(_ donors: [Donor]) throws {
        try ioQueue.sync {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(donors)
            try data.write(to: fileURL, options: .atomic)
        }
    }
}
