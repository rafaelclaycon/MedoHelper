//
//  EpisodeAudioDownloader.swift
//  MedoHelper
//
//  Downloads the original episode MP3 on demand (from the Spreaker enclosure
//  URL found in the RSS feed), caches it in Application Support, and opens
//  the file for cutting — preferably in Audacity when installed.
//

import AppKit
import Foundation

@MainActor
final class EpisodeAudioDownloader: ObservableObject {

    enum State: Equatable {
        case idle
        case downloading(episodeId: String)
        case opening(episodeId: String)
        case failed(episodeId: String, message: String)
    }

    @Published private(set) var state: State = .idle

    /// Candidate Audacity bundle identifiers. Homebrew-installed, App Store,
    /// and older builds historically shipped under different IDs.
    private let audacityBundleIDs = [
        "org.audacityteam.audacity",
        "org.audacityteam.Audacity",
        "com.audacityteam.audacity"
    ]

    // MARK: - Public API

    /// Ensures the MP3 for `episode` is on disk, then opens it.
    /// Cached files are reused; downloads land in `TranscriptStorage.episodesDirectory()`.
    func openInAudacity(episode: PodcastEpisode) async {
        do {
            state = .downloading(episodeId: episode.id)
            let localFile = try await ensureLocalCopy(of: episode)
            state = .opening(episodeId: episode.id)
            open(file: localFile)
            state = .idle
        } catch {
            state = .failed(episodeId: episode.id, message: error.localizedDescription)
        }
    }

    /// Ensures the MP3 is on disk, then reveals it in Finder (no auto-open).
    func revealInFinder(episode: PodcastEpisode) async {
        do {
            state = .downloading(episodeId: episode.id)
            let localFile = try await ensureLocalCopy(of: episode)
            NSWorkspace.shared.activateFileViewerSelecting([localFile])
            state = .idle
        } catch {
            state = .failed(episodeId: episode.id, message: error.localizedDescription)
        }
    }

    /// Returns the cached file URL for an episode if one exists.
    func cachedFileURL(for episodeId: String) -> URL? {
        guard let url = try? TranscriptStorage.episodeAudioURL(for: episodeId),
              FileManager.default.fileExists(atPath: url.path) else { return nil }
        return url
    }

    /// Ensures the MP3 for `episode` is on disk and returns its local URL.
    ///
    /// This entry point is intentionally **silent** — it does not touch
    /// `state`, so other subsystems (e.g. preview playback) can share the
    /// on-disk cache without hiding the Audacity / Finder buttons while
    /// their own spinners are the source of truth for the user.
    func prepareLocalFile(for episode: PodcastEpisode) async throws -> URL {
        try await ensureLocalCopy(of: episode)
    }

    // MARK: - Private

    private func ensureLocalCopy(of episode: PodcastEpisode) async throws -> URL {
        let destination = try TranscriptStorage.episodeAudioURL(for: episode.id)

        if FileManager.default.fileExists(atPath: destination.path) {
            print("ℹ️ [Episode Audio] Cache hit for \(episode.id)")
            return destination
        }

        guard let remote = episode.audioURL else {
            throw EpisodeAudioDownloaderError.missingAudioURL
        }

        print("🔍 [Episode Audio] Downloading \(remote.absoluteString)")

        let (tempURL, response) = try await URLSession.shared.download(from: remote)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            try? FileManager.default.removeItem(at: tempURL)
            throw EpisodeAudioDownloaderError.downloadFailed(status: http.statusCode)
        }

        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: tempURL, to: destination)
        print("✅ [Episode Audio] Saved to \(destination.path)")
        return destination
    }

    private func open(file: URL) {
        if let audacityURL = resolveAudacityURL() {
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            NSWorkspace.shared.open(
                [file],
                withApplicationAt: audacityURL,
                configuration: configuration
            ) { _, error in
                if let error {
                    print("❌ [Episode Audio] Audacity open failed: \(error.localizedDescription) — falling back to default app")
                    DispatchQueue.main.async {
                        NSWorkspace.shared.open(file)
                    }
                }
            }
        } else {
            print("ℹ️ [Episode Audio] Audacity not installed; opening in default app")
            NSWorkspace.shared.open(file)
        }
    }

    private func resolveAudacityURL() -> URL? {
        for bundleID in audacityBundleIDs {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                return url
            }
        }
        // Last-ditch: look for `/Applications/Audacity.app`.
        let fallback = URL(fileURLWithPath: "/Applications/Audacity.app")
        return FileManager.default.fileExists(atPath: fallback.path) ? fallback : nil
    }
}

// MARK: - Errors

enum EpisodeAudioDownloaderError: LocalizedError {

    case missingAudioURL
    case downloadFailed(status: Int)

    var errorDescription: String? {
        switch self {
        case .missingAudioURL:
            return "URL de áudio não encontrada para este episódio."
        case .downloadFailed(let status):
            return "Download do MP3 falhou (HTTP \(status))."
        }
    }
}
