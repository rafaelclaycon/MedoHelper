//
//  TranscriptSearchPanel+ViewModel.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 19/04/26.
//

import Combine
import Foundation
import SwiftUI

extension TranscriptSearchPanel {

    @MainActor
    final class ViewModel: ObservableObject {

        // MARK: - Services (ObservableObjects; owned so the panel is self-contained)

        let downloads: TranscriptDownloadService
        let search: TranscriptSearchService
        let audio: EpisodeAudioDownloader
        let playback: TranscriptPlaybackService

        // MARK: - Search state

        @Published var query: String = ""
        @Published var mode: TranscriptSearchMode = .exact
        @Published private(set) var results: [EpisodeTranscriptGroup] = []
        @Published private(set) var isSearching: Bool = false

        // MARK: - Error surface

        @Published var errorMessage: String?

        // MARK: - Post-download index rebuild

        /// True while `rebuildIndex()` is running after a successful download.
        /// Exposed so the panel can show a distinct status from the download itself.
        @Published private(set) var isRebuildingIndex: Bool = false

        // MARK: - Internal

        private var bag = Set<AnyCancellable>()
        private var searchTask: Task<Void, Never>?

        init(
            downloads: TranscriptDownloadService? = nil,
            search: TranscriptSearchService? = nil,
            audio: EpisodeAudioDownloader? = nil,
            playback: TranscriptPlaybackService? = nil
        ) {
            let resolvedAudio = audio ?? EpisodeAudioDownloader()
            self.downloads = downloads ?? TranscriptDownloadService()
            self.search = search ?? TranscriptSearchService()
            self.audio = resolvedAudio
            self.playback = playback ?? TranscriptPlaybackService(downloader: resolvedAudio)

            bindQueryDebounce()
            forwardChildObjectWillChange()
        }

        /// SwiftUI only observes the top-level `@StateObject`, so when a nested
        /// service (`downloads`, `search`, `audio`, `playback`) publishes a
        /// change, the panel never re-renders. This re-emits every child's
        /// `objectWillChange` on the ViewModel so views wired to the VM stay
        /// in sync with child state like `playback.playing` and `audio.state`.
        private func forwardChildObjectWillChange() {
            let forward: () -> Void = { [weak self] in self?.objectWillChange.send() }
            downloads.objectWillChange.sink { _ in forward() }.store(in: &bag)
            search.objectWillChange.sink { _ in forward() }.store(in: &bag)
            audio.objectWillChange.sink { _ in forward() }.store(in: &bag)
            playback.objectWillChange.sink { _ in forward() }.store(in: &bag)
        }

        // MARK: - Lifecycle

        /// Called from `.task` on the panel. Loads episode metadata and builds
        /// the index from whatever SRT files are already on disk.
        func onFirstAppear() async {
            await search.loadEpisodeMetadata()
            await search.rebuildIndex()
            await runSearch()
        }

        // MARK: - Actions

        func onDownloadAllTapped() async {
            await downloads.downloadAll()
            isRebuildingIndex = true
            await search.rebuildIndex()
            isRebuildingIndex = false
            await runSearch()
        }

        func onDeleteAllTapped() {
            do {
                try downloads.deleteAll()
                results = []
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        func onOpenInAudacityTapped(_ episode: PodcastEpisode) {
            Task { await audio.openInAudacity(episode: episode) }
        }

        func onRevealInFinderTapped(_ episode: PodcastEpisode) {
            Task { await audio.revealInFinder(episode: episode) }
        }

        /// Toggles in-app preview playback for a specific match.
        /// Clicking the same match again (or the current-playing match) stops it.
        func onTogglePreviewTapped(match: TranscriptMatch, episode: PodcastEpisode) {
            playback.toggle(episode: episode, match: match)
        }

        // MARK: - Private

        private func bindQueryDebounce() {
            // Re-run on typed query changes with a short debounce…
            $query
                .removeDuplicates()
                .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
                .sink { [weak self] _ in
                    guard let self else { return }
                    Task { await self.runSearch() }
                }
                .store(in: &bag)

            // …and re-run immediately when the mode is flipped.
            $mode
                .removeDuplicates()
                .dropFirst()
                .sink { [weak self] _ in
                    guard let self else { return }
                    Task { await self.runSearch() }
                }
                .store(in: &bag)
        }

        private func runSearch() async {
            let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
            let activeMode = mode
            searchTask?.cancel()

            guard q.count >= 2 else {
                results = []
                isSearching = false
                return
            }

            isSearching = true
            let task = Task { [search] in
                await search.search(q, mode: activeMode)
            }
            searchTask = Task { [weak self] in
                let found = await task.value
                guard !Task.isCancelled, let self else { return }
                self.results = found
                self.isSearching = false
            }
        }
    }
}
