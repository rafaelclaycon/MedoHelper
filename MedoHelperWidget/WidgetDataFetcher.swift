//
//  WidgetDataFetcher.swift
//  MedoHelperWidget
//
//  Created by Rafael Schmitt on 02/03/26.
//

import Foundation

// MARK: - Response Models

struct WidgetActiveUsersResponse: Codable {
    let activeUsers: Int
}

struct WidgetTopChartItem: Codable {
    let contentName: String
    let contentAuthorName: String
    let shareCount: Int
}

struct WidgetHourlyVersionResponse: Codable {
    let hours: [WidgetHourlySlot]
}

struct WidgetHourlySlot: Codable {
    let hour: Int
    let versions: [WidgetVersionStat]
}

struct WidgetVersionStat: Codable {
    let appVersion: String
    let uniqueUsers: Int
}

struct WidgetVersionDistributionResponse: Codable {
    let versions: [WidgetVersionStat]
}

struct WidgetEpisodeAnalyticsResponse: Codable {
    let totalUniqueUsers: Int
}

struct WidgetTopReaction: Codable {
    let title: String
}

// MARK: - Data Fetcher

struct WidgetDataFetcher {

    private static let serverPath = "https://api.medodelirioios.com/api/"

    private static var analyticsPassword: String? {
        guard let value = Bundle.main.infoDictionary?["AnalyticsPassword"] as? String,
              !value.isEmpty,
              !value.hasPrefix("$(") else {
            return nil
        }
        return value
    }

    // MARK: - Public

    static func fetchAll() async -> AnalyticsEntry {
        async let activeUsersToday = fetchActiveUsersToday()
        async let hourlyUsers = fetchCurrentHourUsers()
        async let version = fetchMostUsedVersion()
        async let episodes = fetchEpisodeUsers()
        async let sound = fetchTopSharedSound()
        async let reaction = fetchTopReaction()

        let todayResult = await activeUsersToday
        let hourlyResult = await hourlyUsers
        let versionResult = await version
        let episodesResult = await episodes
        let soundResult = await sound
        let reactionResult = await reaction

        return AnalyticsEntry(
            date: Date(),
            activeUsersCurrentHour: hourlyResult,
            activeUsersToday: todayResult,
            mostUsedVersion: versionResult?.appVersion,
            mostUsedVersionUsers: versionResult?.uniqueUsers,
            episodeActiveUsers: episodesResult,
            mostSharedSoundName: soundResult?.contentName,
            mostSharedSoundAuthor: soundResult?.contentAuthorName,
            mostSharedSoundCount: soundResult?.shareCount,
            mostOpenedReactionTitle: reactionResult
        )
    }

    // MARK: - Individual Fetchers

    private static func fetchActiveUsersToday() async -> Int? {
        guard let password = analyticsPassword else { return nil }
        let dateString = todayDateString()
        let urlString = serverPath + "v3/active-users-count-from/\(dateString)/\(password)"
        guard let response: WidgetActiveUsersResponse = await get(from: urlString) else { return nil }
        return response.activeUsers
    }

    private static func fetchCurrentHourUsers() async -> Int? {
        guard let password = analyticsPassword else { return nil }
        let dateString = todayDateString()
        let urlString = serverPath + "v4/version-signals-hourly/\(dateString)/\(password)"
        guard let response: WidgetHourlyVersionResponse = await get(from: urlString) else { return nil }

        let currentHour = Calendar.current.component(.hour, from: Date())
        guard let slot = response.hours.first(where: { $0.hour == currentHour }) else { return 0 }
        return slot.versions.reduce(0) { $0 + $1.uniqueUsers }
    }

    private static func fetchMostUsedVersion() async -> WidgetVersionStat? {
        guard let password = analyticsPassword else { return nil }
        let urlString = serverPath + "v4/version-distribution/\(password)"
        guard let response: WidgetVersionDistributionResponse = await get(from: urlString) else { return nil }
        return response.versions.first
    }

    private static func fetchEpisodeUsers() async -> Int? {
        guard let password = analyticsPassword else { return nil }
        let urlString = serverPath + "v4/episode-analytics/\(password)"
        guard let response: WidgetEpisodeAnalyticsResponse = await get(from: urlString) else { return nil }
        return response.totalUniqueUsers
    }

    private static func fetchTopSharedSound() async -> WidgetTopChartItem? {
        let dateString = todayDateString()
        let urlString = serverPath + "v3/sound-share-count-stats-from/\(dateString)"
        guard let items: [WidgetTopChartItem] = await getArray(from: urlString) else { return nil }
        return items.first
    }

    private static func fetchTopReaction() async -> String? {
        let urlString = serverPath + "v4/top-3-reactions"
        guard let reactions: [WidgetTopReaction] = await getArray(from: urlString) else { return nil }
        return reactions.first?.title
    }

    // MARK: - Networking Helpers

    private static func get<T: Decodable>(from urlString: String) async -> T? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            return nil
        }
    }

    private static func getArray<T: Decodable>(from urlString: String) async -> [T]? {
        guard let url = URL(string: urlString) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode([T].self, from: data)
        } catch {
            return nil
        }
    }

    // MARK: - Helpers

    private static func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
