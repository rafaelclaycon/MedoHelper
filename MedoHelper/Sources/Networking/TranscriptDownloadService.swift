//
//  TranscriptDownloadService.swift
//  MedoHelper
//
//  Adapted from MedoDelirioBrasilia's TranscriptDownloadService.
//  Mac-only: no UserDefaults opt-in flag and no in-process notifications —
//  the ViewModel observes this service's published state directly.
//

import CryptoKit
import Foundation

@MainActor
final class TranscriptDownloadService: ObservableObject {

    enum State: Equatable {
        case idle
        /// Manifest is being fetched / diffed against local files.
        /// No per-file progress is knowable yet.
        case preparing
        case downloading(current: Int, total: Int)
        case completed(downloaded: Int, failed: Int)
        case failed(message: String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var localFileCount: Int = 0

    private let session = URLSession(configuration: .default)
    private var isDownloading = false

    init() {
        refreshLocalFileCount()
    }

    // MARK: - Public API

    /// Downloads the manifest and every missing/changed SRT file.
    func downloadAll() async {
        guard !isDownloading else { return }
        isDownloading = true
        state = .preparing
        defer { isDownloading = false }

        do {
            let manifest = try await fetchManifest()
            let toDownload = try diffAgainstLocal(manifest: manifest)

            if toDownload.isEmpty {
                state = .completed(downloaded: 0, failed: 0)
                refreshLocalFileCount()
                return
            }

            var failed = 0
            let total = toDownload.count
            state = .downloading(current: 0, total: total)

            for (index, entry) in toDownload.enumerated() {
                do {
                    try await downloadSRT(entry: entry)
                } catch {
                    print("❌ [Transcripts] \(entry.episodeId) failed: \(error.localizedDescription)")
                    failed += 1
                }
                state = .downloading(current: index + 1, total: total)
            }

            refreshLocalFileCount()
            state = .completed(downloaded: total - failed, failed: failed)
        } catch {
            print("❌ [Transcripts] Download failed: \(error.localizedDescription)")
            state = .failed(message: error.localizedDescription)
        }
    }

    /// Re-counts local `.srt` files. Also called after successful downloads.
    func refreshLocalFileCount() {
        do {
            let dir = try TranscriptStorage.transcriptsDirectory()
            let items = try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            localFileCount = items.filter { $0.pathExtension.lowercased() == "srt" }.count
        } catch {
            localFileCount = 0
        }
    }

    func deleteAll() throws {
        try TranscriptStorage.removeAllTranscripts()
        refreshLocalFileCount()
        state = .idle
    }

    // MARK: - Private

    private func fetchManifest() async throws -> TranscriptManifest {
        let url = URL(string: baseURL + "transcripts/v1/manifest.json")!
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData

        print("🔍 [Transcripts] Fetching manifest from \(url.absoluteString)")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw TranscriptDownloadError.manifestFetchFailed
        }
        let manifest = try JSONDecoder().decode(TranscriptManifest.self, from: data)
        print("✅ [Transcripts] Manifest: \(manifest.files.count) files (v\(manifest.version))")
        return manifest
    }

    private func diffAgainstLocal(manifest: TranscriptManifest) throws -> [TranscriptFileEntry] {
        let dir = try TranscriptStorage.transcriptsDirectory()
        return manifest.files.filter { entry in
            let file = dir.appendingPathComponent("\(entry.episodeId).srt")
            guard FileManager.default.fileExists(atPath: file.path) else { return true }
            guard let data = try? Data(contentsOf: file) else { return true }
            let localHash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            return localHash != entry.hash
        }
    }

    private func downloadSRT(entry: TranscriptFileEntry) async throws {
        let url = URL(string: baseURL + "transcripts/v1/\(entry.episodeId).srt")!
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw TranscriptDownloadError.fileDownloadFailed(entry.episodeId)
        }
        let destination = try TranscriptStorage.transcriptFileURL(for: entry.episodeId)
        try data.write(to: destination, options: .atomic)
    }
}

// MARK: - Errors

enum TranscriptDownloadError: LocalizedError {

    case manifestFetchFailed
    case fileDownloadFailed(String)

    var errorDescription: String? {
        switch self {
        case .manifestFetchFailed:
            return "Não foi possível obter a lista de transcrições do servidor."
        case .fileDownloadFailed(let episodeId):
            return "Falha ao baixar transcrição do episódio \(episodeId)."
        }
    }
}
