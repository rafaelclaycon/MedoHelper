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
        
        // Fetch all data in parallel
        async let activeUsersTask = fetchActiveUsers(date: todayString)
        async let sessionsTask = fetchSessions(date: todayString)
        async let topSoundsTask = fetchTopSharedSounds(date: todayString)
        
        do {
            let (activeUsers, sessions, topSounds) = try await (activeUsersTask, sessionsTask, topSoundsTask)
            
            // Calculate sessions per user
            let sessionsPerUser: Double? = activeUsers > 0 ? Double(sessions) / Double(activeUsers) : nil
            
            print("✅ [Analytics] Successfully fetched all data:")
            print("   - Active Users: \(activeUsers)")
            print("   - Sessions: \(sessions)")
            print("   - Sessions Per User: \(sessionsPerUser.map { String(format: "%.2f", $0) } ?? "N/A")")
            print("   - Top Sounds: \(topSounds.count) items")
            
            return Analytics(
                activeUsers: activeUsers,
                sessionsPerUser: sessionsPerUser,
                topSharedSounds: topSounds
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
}

enum AnalyticsError: Error {
    case invalidURL
}
