//
//  TranscriptSearchService.swift
//  MedoHelper
//
//  Adapted from MedoDelirioBrasilia's SearchService transcript path.
//  Mac-specific: episode metadata (title, pubDate, audioURL) is sourced
//  from the Spreaker RSS feed via `PodcastFeedParser` rather than from a
//  local SQLite database.
//

import Foundation

/// How a user-typed query is matched against transcript cues.
enum TranscriptSearchMode: String, CaseIterable, Identifiable {

    /// The whole query must appear as a contiguous substring
    /// (case- and diacritic-insensitive).
    case exact

    /// Each whitespace-separated token must appear **in order** within the cue,
    /// with any amount of other text allowed between them.
    /// Example: `"banana mamão"` matches `"adoro banana com mamão amarelo"`.
    case anyGap

    var id: String { rawValue }

    var label: String {
        switch self {
        case .exact: return "Exato"
        case .anyGap: return "Entre palavras"
        }
    }

    var help: String {
        switch self {
        case .exact:
            return "A frase inteira deve aparecer, ignorando maiúsculas e acentos."
        case .anyGap:
            return "As palavras podem ter outras palavras entre elas, mas devem aparecer na mesma ordem."
        }
    }
}

@MainActor
final class TranscriptSearchService: ObservableObject {

    struct IndexEntry: Equatable {
        let normalizedText: String
        let originalText: String
        let startTime: TimeInterval
    }

    @Published private(set) var isIndexBuilt: Bool = false
    @Published private(set) var indexedEpisodeCount: Int = 0

    /// Cap of cue matches shown per episode, mirroring the iPhone app.
    private let maxMatchesPerEpisode = 5

    private var index: [String: [IndexEntry]] = [:]
    private var episodes: [String: PodcastEpisode] = [:]

    // MARK: - Public API

    /// Rebuilds the in-memory transcript index from `.srt` files on disk.
    /// Called once at view appear and again whenever transcripts finish downloading.
    func rebuildIndex() async {
        let built = await Task.detached(priority: .userInitiated) {
            Self.buildIndex()
        }.value

        index = built
        indexedEpisodeCount = built.count
        isIndexBuilt = true
        print("✅ [Transcript Search] Indexed \(built.count) episodes, \(built.values.reduce(0) { $0 + $1.count }) cues")
    }

    /// Loads the RSS episode metadata and keeps it mapped by episode ID.
    /// Safe to call multiple times; the feed is cheap to fetch.
    func loadEpisodeMetadata() async {
        do {
            let parser = PodcastFeedParser()
            let all = try await parser.fetchLatestEpisodes()
            episodes = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
            print("✅ [Transcript Search] Loaded metadata for \(all.count) episodes")
        } catch {
            print("❌ [Transcript Search] Failed to load episode metadata: \(error.localizedDescription)")
        }
    }

    /// Runs a substring (or ordered-with-gaps) match over every indexed cue
    /// and groups hits by episode.
    func search(_ query: String, mode: TranscriptSearchMode) async -> [EpisodeTranscriptGroup] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return [] }
        guard !index.isEmpty else { return [] }

        let normalized = trimmed.normalizedForSearch()
        guard !normalized.isEmpty else { return [] }

        // Tokenize for `.anyGap`. A single-token query collapses to `.exact`
        // because the two modes are indistinguishable in that case.
        let tokens = normalized
            .split(separator: " ")
            .map(String.init)
        let effectiveMode: TranscriptSearchMode = (mode == .anyGap && tokens.count > 1) ? .anyGap : .exact

        let snapshot = index
        let episodeMap = episodes
        let cap = maxMatchesPerEpisode

        let groups: [EpisodeTranscriptGroup] = await Task.detached(priority: .userInitiated) {
            var result: [EpisodeTranscriptGroup] = []
            for (episodeId, entries) in snapshot {
                let matching = entries
                    .filter { entry in
                        switch effectiveMode {
                        case .exact:
                            return entry.normalizedText.contains(normalized)
                        case .anyGap:
                            return Self.matchesInOrder(tokens: tokens, in: entry.normalizedText)
                        }
                    }
                    .prefix(cap)

                guard !matching.isEmpty else { continue }

                let episode = episodeMap[episodeId] ?? PodcastEpisode(
                    id: episodeId,
                    title: "Episódio \(episodeId)",
                    pubDate: nil
                )

                result.append(EpisodeTranscriptGroup(
                    episode: episode,
                    matches: matching.map {
                        TranscriptMatch(cueText: $0.originalText, timestamp: $0.startTime)
                    }
                ))
            }
            return result.sorted { lhs, rhs in
                switch (lhs.episode.pubDate, rhs.episode.pubDate) {
                case let (l?, r?): return l > r
                case (nil, _?): return false
                case (_?, nil): return true
                default: return lhs.episode.id > rhs.episode.id
                }
            }
        }.value

        return groups
    }

    // MARK: - Private

    nonisolated private static func buildIndex() -> [String: [IndexEntry]] {
        guard let dir = try? TranscriptStorage.transcriptsDirectory() else { return [:] }
        guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
            return [:]
        }

        var result: [String: [IndexEntry]] = [:]
        for file in files where file.pathExtension.lowercased() == "srt" {
            let stem = file.deletingPathExtension().lastPathComponent
            let episodeId = extractEpisodeId(from: stem)
            guard !episodeId.isEmpty,
                  let content = try? String(contentsOf: file, encoding: .utf8) else { continue }

            let cues = SRTParser.parse(content)
            let entries = cues.map {
                IndexEntry(
                    normalizedText: $0.text.normalizedForSearch(),
                    originalText: $0.text,
                    startTime: $0.startTime
                )
            }
            if !entries.isEmpty {
                result[episodeId] = entries
            }
        }
        return result
    }

    /// Checks that each token appears in `text` in the given order.
    /// `text` and `tokens` are both expected to be already normalized.
    nonisolated static func matchesInOrder(tokens: [String], in text: String) -> Bool {
        var cursor = text.startIndex
        for token in tokens where !token.isEmpty {
            guard let range = text.range(of: token, range: cursor..<text.endIndex) else {
                return false
            }
            cursor = range.upperBound
        }
        return true
    }

    /// Extracts the episode ID prefix from a filename stem (e.g., `"70791487-2026-19"` → `"70791487"`).
    nonisolated private static func extractEpisodeId(from stem: String) -> String {
        if let dashIndex = stem.firstIndex(of: "-") {
            return String(stem[stem.startIndex..<dashIndex])
        }
        if let underscoreIndex = stem.firstIndex(of: "_") {
            return String(stem[stem.startIndex..<underscoreIndex])
        }
        return stem
    }
}
