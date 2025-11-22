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
        
        // Fetch all data in parallel
        async let activeUsersTask = fetchActiveUsers(date: todayString)
        async let sessionsTask = fetchSessions(date: todayString)
        async let topSoundsTask = fetchTopSharedSounds(date: todayString)
        
        let (activeUsers, sessions, topSounds) = try await (activeUsersTask, sessionsTask, topSoundsTask)
        
        return Analytics(
            activeUsers: activeUsers,
            sessions: sessions,
            topSharedSounds: topSounds
        )
    }
    
    private func fetchActiveUsers(date: String) async throws -> Int {
        let url = URL(string: serverPath + "v3/active-users-count-from/\(date)/\(analyticsPassword)")!
        let response: ActiveUsersResponse = try await apiClient.get(from: url)
        return response.activeUsers
    }
    
    private func fetchSessions(date: String) async throws -> Int {
        let url = URL(string: serverPath + "v3/sessions-count-from/\(date)/\(analyticsPassword)")!
        let response: SessionsResponse = try await apiClient.get(from: url)
        return response.sessionsCount
    }
    
    private func fetchTopSharedSounds(date: String) async throws -> [SharedSoundRank] {
        let url = URL(string: serverPath + "v3/sound-share-count-stats-from/\(date)")!
        
        // Fetch data from API
        let topChartItems: [TopChartItem] = try await apiClient.getArray(from: url)
        
        // Convert to SharedSoundRank and take top 3
        let topThree = Array(topChartItems.prefix(3))
        
        return topThree.enumerated().map { index, item in
            SharedSoundRank(
                id: item.contentId,
                soundId: item.contentId,
                soundName: item.contentName,
                authorName: item.contentAuthorName,
                shareCount: item.shareCount,
                rank: index + 1
            )
        }
    }
}

