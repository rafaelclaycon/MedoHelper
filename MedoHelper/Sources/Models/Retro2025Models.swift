//
//  Retro2025Models.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 23/12/25.
//

import Foundation

// MARK: - Share Count Response

struct Retro2025ShareCountResponse: Codable {
    let shareCount: Int
    let date: String
}

// MARK: - Sound Stat

struct Retro2025SoundStat: Codable, Identifiable {
    var id: Int { soundNumber }
    let soundNumber: Int
    let soundName: String
    let shareCount: Int
}

// MARK: - Author Stat

struct Retro2025AuthorStat: Codable, Identifiable {
    var id: String { authorName }
    let authorName: String
    let shareCount: Int
    let imageURL: String?
}

// MARK: - Day of Week Stat

struct Retro2025DayOfWeekStat: Codable, Identifiable {
    var id: String { dayName }
    let dayName: String
    let shareCount: Int
}

// MARK: - User Stat

struct Retro2025UserStat: Codable, Identifiable {
    var id: String { userId }
    let userId: String
    let totalShares: Int
    let mostActiveDay: String?
}

// MARK: - Overall Stats

struct Retro2025OverallStats: Codable {
    let totalShares: Int
    let uniqueUsers: Int
    let averageSharesPerUser: Double
    let startDate: String?
    let endDate: String?
}

// MARK: - Dashboard Response

struct Retro2025DashboardResponse: Codable {
    let overallStats: Retro2025OverallStats
    let topSounds: [Retro2025SoundStat]
    let topAuthors: [Retro2025AuthorStat]
    let dayPatterns: [Retro2025DayOfWeekStat]
    let topUsers: [Retro2025UserStat]
    let date: String?
    let startDate: String?
    let endDate: String?
}
