//
//  ReleaseRolloutModels.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 28/01/26.
//

import Foundation

// MARK: - Hourly Version Response

struct HourlyVersionResponse: Codable, Equatable {
    let date: String
    let hours: [HourlySlot]
    let dayTotals: [VersionStat]
    
    // Server uses camelCase, so no CodingKeys needed
}

// MARK: - Hourly Slot

struct HourlySlot: Codable, Identifiable, Equatable {
    var id: Int { hour }
    let hour: Int
    let versions: [VersionStat]
}

// MARK: - Version Stat

struct VersionStat: Codable, Identifiable, Equatable {
    var id: String { appVersion }
    let appVersion: String
    let uniqueUsers: Int
    let signalCount: Int?
    let percentage: Double?
    
    // Server uses camelCase, so no CodingKeys needed
}

// MARK: - Daily Version Data

struct DailyVersionData: Codable, Identifiable, Equatable {
    var id: String { date }
    let date: String
    let versions: [VersionStat]
}

// MARK: - Daily Version Adoption Response

struct DailyVersionAdoptionResponse: Codable, Equatable {
    let data: [DailyVersionData]
    let days: Int
    
    // Server returns "data" not "daily_data"
}

// MARK: - Version Distribution Response

struct VersionDistributionResponse: Codable, Equatable {
    let date: String
    let totalUsers: Int
    let versions: [VersionStat]
    
    // Server returns "date" and "totalUsers" (not snapshot_time/total_active_users)
}
