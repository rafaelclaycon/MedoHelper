//
//  AnalyticsRepository.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 22/11/25.
//

import Foundation

protocol AnalyticsRepositoryProtocol {
    func fetchAnalytics() async throws -> Analytics
}

final class AnalyticsRepository: AnalyticsRepositoryProtocol {
    
    private let apiClient: APIClient
    
    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }
    
    func fetchAnalytics() async throws -> Analytics {
        // Build date string for all endpoints
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: Date())
        
        print("📊 [Analytics] Fetching analytics for date: \(todayString)")
        
        // Fetch core analytics in parallel
        async let activeUsersTask = fetchActiveUsers(date: todayString)
        async let sessionsTask = fetchSessions(date: todayString)
        async let topSoundsTask = fetchTopSharedSounds(date: todayString)
        
        // Fetch Retro2025 separately (non-blocking)
        let retro2025Task = Task {
            try? await fetchRetro2025Dashboard(startDate: "2025-12-01", endDate: "2025-12-31")
        }
        
        // Fetch daily user counts separately (non-blocking)
        let dailyUsersTask = Task {
            try? await fetchDailyUserCountsLast30Days()
        }
        
        // Fetch device analytics separately (non-blocking)
        let deviceAnalyticsTask = Task {
            try? await fetchDeviceAnalytics()
        }
        
        do {
            let (activeUsers, sessions, topSounds) = try await (activeUsersTask, sessionsTask, topSoundsTask)
            
            // Calculate sessions per user
            let sessionsPerUser: Double? = activeUsers > 0 ? Double(sessions) / Double(activeUsers) : nil
            
            // Get Retro2025 result (may be nil if it failed)
            let retro2025 = try? await retro2025Task.value
            
            // Get daily user counts (may be nil if it failed)
            let dailyUserCounts = try? await dailyUsersTask.value
            
            // Get device analytics (may be nil if it failed)
            let deviceAnalytics = try? await deviceAnalyticsTask.value
            
            print("🔍 [Analytics] Checking device analytics result...")
            if let deviceAnalytics = deviceAnalytics {
                print("✅ [Analytics] Device analytics is NOT nil")
                print("   - iOS Versions count: \(deviceAnalytics.topIOSVersions.count)")
                print("   - Device Models count: \(deviceAnalytics.topDeviceModels.count)")
                print("   - Device Types count: \(deviceAnalytics.topDeviceTypes.count)")
                print("   - Timezones count: \(deviceAnalytics.topTimezones.count)")
            } else {
                print("⚠️ [Analytics] Device analytics is nil - fetch may have failed silently")
            }
            
            print("✅ [Analytics] Successfully fetched all data:")
            print("   - Active Users: \(activeUsers)")
            print("   - Sessions: \(sessions)")
            print("   - Sessions Per User: \(sessionsPerUser.map { String(format: "%.2f", $0) } ?? "N/A")")
            print("   - Top Sounds: \(topSounds.count) items")
            if let retro2025 = retro2025 {
                print("   - Retro2025: Total Shares: \(retro2025.overallStats.totalShares)")
            } else {
                print("   - Retro2025: Failed to load")
            }
            if let dailyUserCounts = dailyUserCounts {
                print("   - Daily User Counts: \(dailyUserCounts.count) days")
            } else {
                print("   - Daily User Counts: Failed to load")
            }
            if let deviceAnalytics = deviceAnalytics {
                print("   - Device Analytics: iOS Versions: \(deviceAnalytics.topIOSVersions.count), Models: \(deviceAnalytics.topDeviceModels.count), Types: \(deviceAnalytics.topDeviceTypes.count), Timezones: \(deviceAnalytics.topTimezones.count)")
            } else {
                print("   - Device Analytics: Failed to load")
            }
            
            return Analytics(
                activeUsers: activeUsers,
                sessionsPerUser: sessionsPerUser,
                topSharedSounds: topSounds,
                retro2025: retro2025,
                dailyUserCounts: dailyUserCounts,
                deviceAnalytics: deviceAnalytics
            )
        } catch {
            print("❌ [Analytics] Error fetching analytics: \(error)")
            print("   Error details: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func fetchActiveUsers(date: String) async throws -> Int {
        let urlString = serverPath + "v3/active-users-count-from/\(date)/\(analyticsPassword)"
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
    
    private func fetchSessions(date: String) async throws -> Int {
        let urlString = serverPath + "v3/sessions-count-from/\(date)/\(analyticsPassword)"
        print("🔍 [Sessions] Fetching from: \(urlString)")
        
        guard let url = URL(string: urlString) else {
            print("❌ [Sessions] Invalid URL: \(urlString)")
            throw AnalyticsError.invalidURL
        }
        
        do {
            let response: SessionsResponse = try await apiClient.get(from: url)
            print("✅ [Sessions] Success: \(response.sessionsCount) sessions")
            return response.sessionsCount
        } catch {
            print("❌ [Sessions] Failed: \(error)")
            throw error
        }
    }
    
    private func fetchTopSharedSounds(date: String) async throws -> [SharedSoundRank] {
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
        let urlString = serverPath + "v3/active-users-daily-last-30-days/\(analyticsPassword)"
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
        let urlString = serverPath + "v3/device-analytics/\(analyticsPassword)"
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
}

enum AnalyticsError: Error {
    case invalidURL
}
