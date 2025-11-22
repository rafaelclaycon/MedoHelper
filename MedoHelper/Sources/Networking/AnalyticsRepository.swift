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
        // Fetch real data for top shared sounds
        let topSounds = try await fetchTopSharedSounds()
        
        // Generate mock data for active users and sessions
        let activeUsers = Int.random(in: 50...150)
        let sessions = Int.random(in: 100...300)
        
        return Analytics(
            activeUsers: activeUsers,
            sessions: sessions,
            topSharedSounds: topSounds
        )
    }
    
    private func fetchTopSharedSounds() async throws -> [SharedSoundRank] {
        // Build URL with today's date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: Date())
        
        let url = URL(string: serverPath + "v3/sound-share-count-stats-from/\(todayString)")!
        
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

