//
//  PodcastFeedParser.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 04/04/26.
//

import Foundation

final class PodcastFeedParser: NSObject, XMLParserDelegate {

    private static let feedURL = "https://www.spreaker.com/show/4711842/episodes/feed"

    private var episodes: [PodcastEpisode] = []
    private let maxEpisodes: Int

    private var insideItem = false
    private var currentElement = ""
    private var currentTitle = ""
    private var currentGUID = ""
    private var currentPubDate = ""

    private var continuation: CheckedContinuation<[PodcastEpisode], Error>?

    init(maxEpisodes: Int = 10) {
        self.maxEpisodes = maxEpisodes
    }

    func fetchLatestEpisodes() async throws -> [PodcastEpisode] {
        guard let url = URL(string: Self.feedURL) else {
            throw URLError(.badURL)
        }
        let (data, _) = try await URLSession.shared.data(from: url)

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            self.episodes = []
            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.parse()
        }
    }

    // MARK: - XMLParserDelegate

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String] = [:]
    ) {
        currentElement = elementName
        if elementName == "item" {
            insideItem = true
            currentTitle = ""
            currentGUID = ""
            currentPubDate = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard insideItem else { return }
        switch currentElement {
        case "title":
            currentTitle += string
        case "guid":
            currentGUID += string
        case "pubDate":
            currentPubDate += string
        default:
            break
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?
    ) {
        guard elementName == "item" else { return }
        insideItem = false

        let episodeID = extractSpreakerID(from: currentGUID.trimmingCharacters(in: .whitespacesAndNewlines))
        let episode = PodcastEpisode(
            id: episodeID,
            title: currentTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            pubDate: parseRSSDate(currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines))
        )
        episodes.append(episode)

        if episodes.count >= maxEpisodes {
            parser.abortParsing()
            continuation?.resume(returning: episodes)
            continuation = nil
        }
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        continuation?.resume(returning: episodes)
        continuation = nil
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        if !episodes.isEmpty {
            continuation?.resume(returning: episodes)
        } else {
            continuation?.resume(throwing: parseError)
        }
        continuation = nil
    }

    // MARK: - Helpers

    private func extractSpreakerID(from guid: String) -> String {
        // guid format: "https://api.spreaker.com/episode/71090296"
        if let lastComponent = guid.split(separator: "/").last {
            return String(lastComponent)
        }
        return guid
    }

    private func parseRSSDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return formatter.date(from: string)
    }
}
