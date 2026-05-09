//
//  TranscriptPlaybackService.swift
//  MedoHelper
//
//  Plays a short preview of a transcript match directly inside the app so
//  the user can confirm it's the right excerpt before going to Audacity.
//

import AVFoundation
import Foundation

@MainActor
final class TranscriptPlaybackService: NSObject, ObservableObject {

    /// Identifies a specific cue inside a specific episode. Used both for
    /// the "currently playing" indicator and for the "preparing" spinner.
    struct Excerpt: Equatable, Hashable {
        let episodeId: String
        let timestamp: TimeInterval
    }

    @Published private(set) var playing: Excerpt?
    @Published private(set) var preparing: Excerpt?

    /// How long a preview plays before it auto-stops. The user can stop
    /// earlier or click another match (which cancels this one).
    var autoStopAfter: TimeInterval = 15

    private let downloader: EpisodeAudioDownloader

    private var player: AVAudioPlayer?
    private var prepareTask: Task<Void, Never>?
    private var autoStopTask: Task<Void, Never>?

    init(downloader: EpisodeAudioDownloader) {
        self.downloader = downloader
        super.init()
    }

    deinit {
        // AVAudioPlayer cleans itself up; explicit stop is belt-and-suspenders.
        player?.stop()
    }

    // MARK: - Public API

    /// Returns `true` if `excerpt` is the one currently preparing or playing.
    func isActive(_ excerpt: Excerpt) -> Bool {
        playing == excerpt || preparing == excerpt
    }

    /// If `excerpt` is active, stops it. Otherwise starts preparing+playing it.
    /// Tapping any new excerpt implicitly stops the previous one.
    func toggle(episode: PodcastEpisode, match: TranscriptMatch) {
        let target = Excerpt(episodeId: episode.id, timestamp: match.timestamp)
        if isActive(target) {
            stop()
        } else {
            play(episode: episode, match: match)
        }
    }

    func play(episode: PodcastEpisode, match: TranscriptMatch) {
        let target = Excerpt(episodeId: episode.id, timestamp: match.timestamp)

        // Cancel any in-flight prepare + stop current playback cleanly.
        prepareTask?.cancel()
        autoStopTask?.cancel()
        teardownPlayer()

        preparing = target

        prepareTask = Task { [weak self] in
            guard let self else { return }
            do {
                let fileURL = try await self.downloader.prepareLocalFile(for: episode)
                if Task.isCancelled { return }

                let player = try AVAudioPlayer(contentsOf: fileURL)
                player.delegate = self
                guard player.prepareToPlay() else {
                    throw PlaybackError.prepareFailed
                }

                // Clamp the seek to the file duration so we don't kick ourselves off the end.
                let clamped = min(max(match.timestamp, 0), max(player.duration - 0.1, 0))
                player.currentTime = clamped

                guard player.play() else {
                    throw PlaybackError.playFailed
                }

                if Task.isCancelled {
                    player.stop()
                    return
                }

                self.player = player
                self.preparing = nil
                self.playing = target

                self.scheduleAutoStop(for: target)
            } catch {
                if !Task.isCancelled {
                    print("❌ [Playback] \(error.localizedDescription)")
                }
                self.preparing = nil
                self.playing = nil
            }
        }
    }

    func stop() {
        prepareTask?.cancel()
        prepareTask = nil
        autoStopTask?.cancel()
        autoStopTask = nil
        teardownPlayer()
        preparing = nil
    }

    // MARK: - Private

    private func teardownPlayer() {
        player?.stop()
        player = nil
        playing = nil
    }

    private func scheduleAutoStop(for excerpt: Excerpt) {
        autoStopTask?.cancel()
        let window = autoStopAfter
        autoStopTask = Task { [weak self] in
            let ns = UInt64(max(window, 0) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: ns)
            guard !Task.isCancelled, let self else { return }
            // Only stop if *this* excerpt is still the active one.
            if self.playing == excerpt {
                self.teardownPlayer()
            }
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension TranscriptPlaybackService: AVAudioPlayerDelegate {

    nonisolated func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        Task { @MainActor [weak self] in
            self?.teardownPlayer()
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(
        _ player: AVAudioPlayer,
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            print("❌ [Playback] Decode error: \(error?.localizedDescription ?? "unknown")")
            self?.teardownPlayer()
        }
    }
}

// MARK: - Errors

enum PlaybackError: LocalizedError {

    case prepareFailed
    case playFailed

    var errorDescription: String? {
        switch self {
        case .prepareFailed: return "Não foi possível preparar o áudio para tocar."
        case .playFailed: return "Não foi possível iniciar a reprodução."
        }
    }
}
