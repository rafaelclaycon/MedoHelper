//
//  AnalyticsRepository.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 22/11/25.
//

import Foundation

protocol AnalyticsRepositoryProtocol {
    func fetchActiveUsers(date: String) async throws -> Int
    func fetchDailyUserCountsLast30Days() async throws -> [DailyUserCount]
    func fetchTopSharedSounds(date: String) async throws -> [SharedSoundRank]
    func fetchDeviceAnalytics() async throws -> DeviceAnalyticsResponse
    func fetchDeviceModelHistory(modelName: String) async throws -> DeviceModelHistoryResponse
    func fetchAllDeviceModelNames() async throws -> [String]
    func fetchIOSVersionHistory(majorVersion: String) async throws -> IOSVersionHistoryResponse
    func fetchAllIOSVersions() async throws -> [String]
    func fetchIOSVersionDeviceBreakdown(majorVersion: String) async throws -> IOSVersionDeviceBreakdownResponse
    func fetchNavigationAnalytics() async throws -> NavigationAnalyticsResponse
    func fetchRetro2025Dashboard(startDate: String, endDate: String) async throws -> Retro2025DashboardResponse
    
    // Release Rollout
    func fetchHourlyVersionData(date: String) async throws -> HourlyVersionResponse
    func fetchDailyVersionAdoption(days: Int) async throws -> [DailyVersionData]
    func fetchVersionDistribution() async throws -> VersionDistributionResponse
    
    // Episodes
    func fetchEpisodeAnalytics() async throws -> EpisodeAnalyticsResponse
    func fetchTranscriptStatuses() async throws -> [PodcastEpisode]
    
    // Reactions
    func fetchTopReactions() async throws -> [ServerReaction]
}

final class AnalyticsRepository: AnalyticsRepositoryProtocol {
    
    private let apiClient: APIClient
    
    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }
    
    func fetchActiveUsers(date: String) async throws -> Int {
        let urlString = serverPath + "v3/active-users-count-from/\(date)/\(Secrets.analyticsPassword)"
        print("🔍 [Active Users] Fetching from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [Active Users] Invalid URL: \(urlString)")
            throw AnalyticsError.invalidURL
        }
        
        do {
            let response: ActiveUsersResponse = try await apiClient.get(from: url)
            print("✅ [Active Users] Success: \(response.activeUsers) users")
            return response.activeUsers
        } catch {
            print("❌ [Active Users] Failed: \(error)")
            throw error
        }
    }
    
    func fetchTopSharedSounds(date: String) async throws -> [SharedSoundRank] {
        let urlString = serverPath + "v3/sound-share-count-stats-from/\(date)"
        print("🔍 [Top Sounds] Fetching from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [Top Sounds] Invalid URL: \(urlString)")
            throw AnalyticsError.invalidURL
        }
        
        do {
            // Fetch data from API
            let topChartItems: [TopChartItem] = try await apiClient.getArray(from: url)
            print("✅ [Top Sounds] Success: Received \(topChartItems.count) items")
            
            // Convert to SharedSoundRank and take top 3
            let topThree = Array(topChartItems.prefix(3))
            
            let result = topThree.enumerated().map { index, item in
                SharedSoundRank(
                    id: item.contentId,
                    soundId: item.contentId,
                    soundName: item.contentName,
                    authorName: item.contentAuthorName,
                    shareCount: item.shareCount,
                    rank: index + 1
                )
            }
            
            print("   Top 3:")
            result.forEach { sound in
                print("   \(sound.rank). \(sound.soundName) - \(sound.shareCount) shares")
            }
            
            return result
        } catch {
            print("❌ [Top Sounds] Failed: \(error)")
            throw error
        }
    }
    
    func fetchRetro2025Dashboard(startDate: String, endDate: String) async throws -> Retro2025DashboardResponse {
        let urlString = serverPath + "v4/retro2025-dashboard-range/\(startDate)/\(endDate)"
        print("🔍 [Retro2025] Fetching dashboard from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [Retro2025] Invalid URL: \(urlString)")
            throw AnalyticsError.invalidURL
        }
        
        do {
            let response: Retro2025DashboardResponse = try await apiClient.get(from: url)
            print("✅ [Retro2025] Success: Total Shares: \(response.overallStats.totalShares), Unique Users: \(response.overallStats.uniqueUsers)")
            return response
        } catch {
            print("❌ [Retro2025] Failed: \(error)")
            throw error
        }
    }
    
    func fetchDailyUserCountsLast30Days() async throws -> [DailyUserCount] {
        let urlString = serverPath + "v3/active-users-daily-last-30-days/\(Secrets.analyticsPassword)"
        print("🔍 [Daily Users] Fetching from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [Daily Users] Invalid URL: \(urlString)")
            throw AnalyticsError.invalidURL
        }
        
        do {
            // The API returns an array of {date: String, activeUsers: Int}
            // We need to map it to DailyUserCount which uses {date: String, count: Int}
            struct DailyUserCountResponse: Codable {
                let date: String
                let activeUsers: Int
            }
            
            let responses: [DailyUserCountResponse] = try await apiClient.getArray(from: url)
            
            // Map to DailyUserCount format
            let results = responses.map { response in
                DailyUserCount(id: response.date, date: response.date, count: response.activeUsers)
            }
            
            print("✅ [Daily Users] Successfully fetched \(results.count) days of data")
            return results
        } catch {
            print("❌ [Daily Users] Failed: \(error)")
            throw error
        }
    }
    
    func fetchDeviceAnalytics() async throws -> DeviceAnalyticsResponse {
        let urlString = serverPath + "v3/device-analytics/\(Secrets.analyticsPassword)"
        print("🔍 [Device Analytics] Fetching from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [Device Analytics] Invalid URL: \(urlString)")
            throw AnalyticsError.invalidURL
        }
        
        do {
            // Fetch raw data first to debug
            let (data, _) = try await URLSession.shared.data(from: url)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔍 [Device Analytics] Raw JSON response (first 500 chars):")
                print(String(jsonString.prefix(500)))
            }
            
            // Try to parse as dictionary to see what keys are actually present
            if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("🔍 [Device Analytics] JSON keys found: \(jsonObject.keys.sorted())")
            }
            
            // Decode manually - with explicit CodingKeys, we don't need convertFromSnakeCase
            let decoder = JSONDecoder()
            // Don't use convertFromSnakeCase since we have explicit CodingKeys
            let response = try decoder.decode(DeviceAnalyticsResponse.self, from: data)
            
            print("✅ [Device Analytics] Success:")
            print("   - iOS Versions: \(response.topIOSVersions.count) groups")
            response.topIOSVersions.forEach { version in
                print("      • \(version.displayName): \(version.count)")
            }
            print("   - Device Models: \(response.topDeviceModels.count) models")
            response.topDeviceModels.prefix(5).forEach { model in
                print("      • \(model.modelName): \(model.count)")
            }
            print("   - Device Types: \(response.topDeviceTypes.count) types")
            response.topDeviceTypes.forEach { type in
                print("      • \(type.deviceType): \(type.count)")
            }
            print("   - Timezones: \(response.topTimezones.count) timezones")
            response.topTimezones.prefix(5).forEach { tz in
                print("      • \(tz.timezone): \(tz.count)")
            }
            return response
        } catch {
            print("❌ [Device Analytics] Failed: \(error)")
            print("   Error type: \(type(of: error))")
            print("   Error description: \(error.localizedDescription)")
            if let urlError = error as? URLError {
                print("   URL Error code: \(urlError.code.rawValue)")
                print("   URL Error description: \(urlError.localizedDescription)")
            }
            throw error
        }
    }
    
    func fetchDeviceModelHistory(modelName: String) async throws -> DeviceModelHistoryResponse {
        guard let encodedName = modelName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw AnalyticsError.invalidURL
        }
        let urlString = serverPath + "v3/device-model-history/\(encodedName)/\(Secrets.analyticsPassword)"
        print("🔍 [Device Model History] Fetching from: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("❌ [Device Model History] Invalid URL: \(urlString)")
            throw AnalyticsError.invalidURL
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            let response = try decoder.decode(DeviceModelHistoryResponse.self, from: data)
            print("✅ [Device Model History] Success: \(response.history.count) months for \(response.modelName)")
            return response
        } catch {
            print("❌ [Device Model History] Failed: \(error)")
            throw error
        }
    }

    func fetchAllDeviceModelNames() async throws -> [String] {
        let urlString = serverPath + "v3/all-device-model-names/\(Secrets.analyticsPassword)"
        print("🔍 [All Device Models] Fetching from: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("❌ [All Device Models] Invalid URL: \(urlString)")
            throw AnalyticsError.invalidURL
        }

        do {
            let names: [String] = try await apiClient.getArray(from: url)
            print("✅ [All Device Models] Success: \(names.count) models")
            return names
        } catch {
            print("❌ [All Device Models] Failed: \(error)")
            throw error
        }
    }

    func fetchIOSVersionHistory(majorVersion: String) async throws -> IOSVersionHistoryResponse {
        let urlString = serverPath + "v3/ios-version-history/\(majorVersion)/\(Secrets.analyticsPassword)"
        print("🔍 [iOS Version History] Fetching from: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("❌ [iOS Version History] Invalid URL: \(urlString)")
            throw AnalyticsError.invalidURL
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(IOSVersionHistoryResponse.self, from: data)
            print("✅ [iOS Version History] Success: \(response.history.count) months for iOS \(response.majorVersion)")
            return response
        } catch {
            print("❌ [iOS Version History] Failed: \(error)")
            throw error
        }
    }

    func fetchAllIOSVersions() async throws -> [String] {
        let urlString = serverPath + "v3/all-ios-versions/\(Secrets.analyticsPassword)"
        print("🔍 [All iOS Versions] Fetching from: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("❌ [All iOS Versions] Invalid URL: \(urlString)")
            throw AnalyticsError.invalidURL
        }

        do {
            let versions: [String] = try await apiClient.getArray(from: url)
            print("✅ [All iOS Versions] Success: \(versions.count) versions")
            return versions
        } catch {
            print("❌ [All iOS Versions] Failed: \(error)")
            throw error
        }
    }

    func fetchIOSVersionDeviceBreakdown(majorVersion: String) async throws -> IOSVersionDeviceBreakdownResponse {
        let urlString = serverPath + "v3/ios-version-device-breakdown/\(majorVersion)/\(Secrets.analyticsPassword)"
        print("🔍 [iOS Version Breakdown] Fetching from: \(urlString)")

        guard let url = URL(string: urlString) else {
            print("❌ [iOS Version Breakdown] Invalid URL: \(urlString)")
            throw AnalyticsError.invalidURL
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(IOSVersionDeviceBreakdownResponse.self, from: data)
            print("✅ [iOS Version Breakdown] Success: \(response.devices.count) devices for iOS \(response.majorVersion)")
            return response
        } catch {
            print("❌ [iOS Version Breakdown] Failed: \(error)")
            throw error
        }
    }

    func fetchNavigationAnalytics() async throws -> NavigationAnalyticsResponse {
        let urlString = serverPath + "v3/navigation-analytics/\(Secrets.analyticsPassword)"
        print("🔍 [Navigation Analytics] Fetching from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [Navigation Analytics] Invalid URL: \(urlString)")
            throw AnalyticsError.invalidURL
        }
        
        do {
            // Fetch raw data first to debug
            let (data, _) = try await URLSession.shared.data(from: url)
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔍 [Navigation Analytics] Raw JSON response (first 500 chars):")
                print(String(jsonString.prefix(500)))
            }
            
            // Try to parse as dictionary to see what keys are actually present
            if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("🔍 [Navigation Analytics] JSON keys found: \(jsonObject.keys.sorted())")
            }
            
            // Decode manually - with explicit CodingKeys, we don't need convertFromSnakeCase
            let decoder = JSONDecoder()
            let response = try decoder.decode(NavigationAnalyticsResponse.self, from: data)
            print("✅ [Navigation Analytics] Success:")
            print("   - Top Screens: \(response.topScreens.count) screens")
            print("   - Total Views: \(response.totalViews)")
            response.topScreens.prefix(10).forEach { screen in
                print("      • \(screen.displayName): \(screen.viewCount)")
            }
            return response
        } catch {
            print("❌ [Navigation Analytics] Failed: \(error)")
            print("   Error type: \(type(of: error))")
            print("   Error description: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Release Rollout
    
    func fetchHourlyVersionData(date: String) async throws -> HourlyVersionResponse {
        let urlString = serverPath + "v4/version-signals-hourly/\(date)/\(Secrets.analyticsPassword)"
        print("🔍 [Hourly Version] Fetching from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [Hourly Version] Invalid URL: \(urlString)")
            throw AnalyticsError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Log HTTP response status
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 [Hourly Version] HTTP Status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    print("⚠️ [Hourly Version] Non-200 status code received")
                }
            }
            
            // Log raw response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔍 [Hourly Version] Raw JSON response (\(data.count) bytes):")
                print(jsonString)
            }
            
            // Try to parse as dictionary to see structure
            if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("🔍 [Hourly Version] JSON keys found: \(jsonObject.keys.sorted())")
            }
            
            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(HourlyVersionResponse.self, from: data)
            print("✅ [Hourly Version] Success:")
            print("   - Date: \(decodedResponse.date)")
            print("   - Hours with data: \(decodedResponse.hours.count)")
            print("   - Versions: \(decodedResponse.dayTotals.count)")
            decodedResponse.dayTotals.prefix(5).forEach { version in
                print("      • \(version.appVersion): \(version.uniqueUsers) users")
            }
            return decodedResponse
        } catch let decodingError as DecodingError {
            print("❌ [Hourly Version] Decoding Error:")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("   Key '\(key.stringValue)' not found: \(context.debugDescription)")
                print("   Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .typeMismatch(let type, let context):
                print("   Type mismatch for \(type): \(context.debugDescription)")
                print("   Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .valueNotFound(let type, let context):
                print("   Value of type \(type) not found: \(context.debugDescription)")
                print("   Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .dataCorrupted(let context):
                print("   Data corrupted: \(context.debugDescription)")
                print("   Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            @unknown default:
                print("   Unknown decoding error: \(decodingError)")
            }
            throw decodingError
        } catch {
            print("❌ [Hourly Version] Failed: \(error)")
            print("   Error type: \(type(of: error))")
            print("   Error description: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchDailyVersionAdoption(days: Int) async throws -> [DailyVersionData] {
        let urlString = serverPath + "v4/version-adoption-daily/\(days)/\(Secrets.analyticsPassword)"
        print("🔍 [Daily Version] Fetching from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [Daily Version] Invalid URL: \(urlString)")
            throw AnalyticsError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Log HTTP response status
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 [Daily Version] HTTP Status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    print("⚠️ [Daily Version] Non-200 status code received")
                }
            }
            
            // Log raw response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔍 [Daily Version] Raw JSON response (\(data.count) bytes):")
                print(jsonString)
            }
            
            // Try to parse as dictionary to see structure
            if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("🔍 [Daily Version] JSON keys found: \(jsonObject.keys.sorted())")
            }
            
            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(DailyVersionAdoptionResponse.self, from: data)
            print("✅ [Daily Version] Success:")
            print("   - Days: \(decodedResponse.data.count)")
            return decodedResponse.data
        } catch let decodingError as DecodingError {
            print("❌ [Daily Version] Decoding Error:")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("   Key '\(key.stringValue)' not found: \(context.debugDescription)")
                print("   Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .typeMismatch(let type, let context):
                print("   Type mismatch for \(type): \(context.debugDescription)")
                print("   Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .valueNotFound(let type, let context):
                print("   Value of type \(type) not found: \(context.debugDescription)")
                print("   Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .dataCorrupted(let context):
                print("   Data corrupted: \(context.debugDescription)")
                print("   Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            @unknown default:
                print("   Unknown decoding error: \(decodingError)")
            }
            throw decodingError
        } catch {
            print("❌ [Daily Version] Failed: \(error)")
            print("   Error type: \(type(of: error))")
            print("   Error description: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchVersionDistribution() async throws -> VersionDistributionResponse {
        let urlString = serverPath + "v4/version-distribution/\(Secrets.analyticsPassword)"
        print("🔍 [Version Distribution] Fetching from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [Version Distribution] Invalid URL: \(urlString)")
            throw AnalyticsError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Log HTTP response status
            if let httpResponse = response as? HTTPURLResponse {
                print("🔍 [Version Distribution] HTTP Status: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    print("⚠️ [Version Distribution] Non-200 status code received")
                }
            }
            
            // Log raw response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔍 [Version Distribution] Raw JSON response (\(data.count) bytes):")
                print(jsonString)
            }
            
            // Try to parse as dictionary to see structure
            if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("🔍 [Version Distribution] JSON keys found: \(jsonObject.keys.sorted())")
            }
            
            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(VersionDistributionResponse.self, from: data)
            print("✅ [Version Distribution] Success:")
            print("   - Date: \(decodedResponse.date)")
            print("   - Total Users: \(decodedResponse.totalUsers)")
            print("   - Versions: \(decodedResponse.versions.count)")
            decodedResponse.versions.prefix(5).forEach { version in
                let pct = version.percentage.map { String(format: "%.1f%%", $0) } ?? "N/A"
                print("      • \(version.appVersion): \(version.uniqueUsers) users (\(pct))")
            }
            return decodedResponse
        } catch let decodingError as DecodingError {
            print("❌ [Version Distribution] Decoding Error:")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("   Key '\(key.stringValue)' not found: \(context.debugDescription)")
                print("   Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .typeMismatch(let type, let context):
                print("   Type mismatch for \(type): \(context.debugDescription)")
                print("   Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .valueNotFound(let type, let context):
                print("   Value of type \(type) not found: \(context.debugDescription)")
                print("   Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            case .dataCorrupted(let context):
                print("   Data corrupted: \(context.debugDescription)")
                print("   Coding path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            @unknown default:
                print("   Unknown decoding error: \(decodingError)")
            }
            throw decodingError
        } catch {
            print("❌ [Version Distribution] Failed: \(error)")
            print("   Error type: \(type(of: error))")
            print("   Error description: \(error.localizedDescription)")
            throw error
        }
    }
    // MARK: - Episodes
    
    func fetchEpisodeAnalytics() async throws -> EpisodeAnalyticsResponse {
        let urlString = serverPath + "v4/episode-analytics/\(Secrets.analyticsPassword)"
        print("🔍 [Episode Analytics] Fetching from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [Episode Analytics] Invalid URL: \(urlString)")
            throw AnalyticsError.invalidURL
        }
        
        do {
            let response: EpisodeAnalyticsResponse = try await apiClient.get(from: url)
            print("✅ [Episode Analytics] Success: \(response.totalUniqueUsers) unique users, \(response.usersWhoPlayed) played, \(response.usersWhoBookmarked) bookmarked")
            return response
        } catch {
            print("❌ [Episode Analytics] Failed: \(error)")
            throw error
        }
    }
    
    func fetchTranscriptStatuses() async throws -> [PodcastEpisode] {
        print("🔍 [Transcripts] Fetching RSS feed and checking transcript files...")
        let parser = PodcastFeedParser(maxEpisodes: 10)
        let episodes = try await parser.fetchLatestEpisodes()
        print("✅ [Transcripts] Parsed \(episodes.count) episodes from feed")

        let checker = TranscriptChecker()
        let results = await checker.checkTranscripts(for: episodes)
        let transcribed = results.filter(\.isTranscribed).count
        print("✅ [Transcripts] \(transcribed)/\(results.count) episodes have transcripts")
        return results
    }
    
    // MARK: - Reactions
    
    func fetchTopReactions() async throws -> [ServerReaction] {
        let urlString = serverPath + "v4/top-3-reactions"
        print("🔍 [Top Reactions] Fetching from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [Top Reactions] Invalid URL: \(urlString)")
            throw AnalyticsError.invalidURL
        }
        
        do {
            let reactions: [ServerReaction] = try await apiClient.getArray(from: url)
            print("✅ [Top Reactions] Success: \(reactions.count) reactions")
            reactions.forEach { reaction in
                print("   • \(reaction.title)")
            }
            return reactions
        } catch {
            print("❌ [Top Reactions] Failed: \(error)")
            throw error
        }
    }
}

enum AnalyticsError: Error {
    case invalidURL
}
