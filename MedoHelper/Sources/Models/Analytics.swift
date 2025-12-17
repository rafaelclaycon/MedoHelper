//
//  Analytics.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 22/11/25.
//

import Foundation

struct Analytics: Codable {
    let activeUsers: Int
    let sessionsPerUser: Double?
    let topSharedSounds: [SharedSoundRank]
    let retro2025: Retro2025DashboardResponse?
    let dailyUserCounts: [DailyUserCount]?
    let deviceAnalytics: DeviceAnalyticsResponse?
}

