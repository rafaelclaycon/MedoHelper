//
//  TranscriptChecker.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 04/04/26.
//

import Foundation

struct TranscriptChecker {

    func checkTranscripts(for episodes: [PodcastEpisode]) async -> [PodcastEpisode] {
        await withTaskGroup(of: (String, Bool).self) { group in
            for episode in episodes {
                group.addTask {
                    let exists = await self.transcriptExists(for: episode.id)
                    return (episode.id, exists)
                }
            }

            var results: [String: Bool] = [:]
            for await (id, exists) in group {
                results[id] = exists
            }

            return episodes.map { episode in
                var copy = episode
                copy.isTranscribed = results[episode.id] ?? false
                return copy
            }
        }
    }

    private func transcriptExists(for episodeID: String) async -> Bool {
        let urlString = baseURL + "transcripts/v1/\(episodeID).srt"
        guard let url = URL(string: urlString) else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else { return false }
            return httpResponse.statusCode == 200
        } catch {
            return false
        }
    }
}
