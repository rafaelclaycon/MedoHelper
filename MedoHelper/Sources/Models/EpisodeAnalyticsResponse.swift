//
//  EpisodeAnalyticsResponse.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 26/02/26.
//

import Foundation

struct EpisodeAnalyticsResponse: Codable, Equatable {
    let dailyUniqueUsers: [EpisodeDailyUserCount]
    let totalUniqueUsers: Int
    let usersWhoPlayed: Int
    let usersWhoBookmarked: Int
    let averagePlaysPerUser: Double
    let averageBookmarksPerUser: Double
}

struct EpisodeDailyUserCount: Codable, Identifiable, Equatable {
    var id: String { date }
    let date: String
    let activeUsers: Int

    var dateValue: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
}
