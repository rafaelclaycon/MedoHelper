//
//  TranscriptModels.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 19/04/26.
//

import Foundation

// MARK: - Manifest

struct TranscriptManifest: Codable, Equatable {

    let version: Int
    let files: [TranscriptFileEntry]
}

struct TranscriptFileEntry: Codable, Equatable {

    let episodeId: String
    let hash: String
    let size: Int
}

// MARK: - Search Results

struct EpisodeTranscriptGroup: Identifiable, Equatable {

    let episode: PodcastEpisode
    let matches: [TranscriptMatch]

    var id: String { episode.id }
}

struct TranscriptMatch: Identifiable, Equatable, Hashable {

    let cueText: String
    let timestamp: TimeInterval

    var id: String { "\(Int(timestamp))-\(cueText.hashValue)" }

    var formattedTimestamp: String {
        let totalSeconds = Int(timestamp)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}
