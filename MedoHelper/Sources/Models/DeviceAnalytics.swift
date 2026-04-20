//
//  DeviceAnalytics.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 23/12/25.
//

import Foundation

// MARK: - Device Analytics Response

struct DeviceAnalyticsResponse: Codable, Equatable {
    let topIOSVersions: [IOSVersionStat]
    let topDeviceModels: [DeviceModelStat]
    let topDeviceTypes: [DeviceTypeStat]
    let topTimezones: [TimezoneStat]
    let totalTimezonesCount: Int
    
    enum CodingKeys: String, CodingKey {
        case topIOSVersions = "top_ios_versions"
        case topDeviceModels = "top_device_models"
        case topDeviceTypes = "top_device_types"
        case topTimezones = "top_timezones"
        case totalTimezonesCount = "total_timezones_count"
    }
}

// MARK: - iOS Version Stat

struct IOSVersionStat: Codable, Identifiable, Equatable {
    let id: String // major version number (e.g., "15", "16", "17", "18")
    let majorVersion: String // major version number
    let count: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case majorVersion = "major_version"
        case count
    }
    
    var displayName: String {
        "iOS \(majorVersion)"
    }
}

// MARK: - Device Model Stat

struct DeviceModelStat: Codable, Identifiable, Equatable {
    let id: String // modelName
    let modelName: String
    let count: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case modelName = "model_name"
        case count
    }
}

// MARK: - Device Type Stat

struct DeviceTypeStat: Codable, Identifiable, Equatable {
    let id: String // "iPhone", "iPad", "Mac"
    let deviceType: String
    let count: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case deviceType = "device_type"
        case count
    }
    
    var iconName: String {
        switch deviceType {
        case "iPhone": return "iphone"
        case "iPad": return "ipad"
        case "Mac": return "desktopcomputer"
        default: return "device.iphone"
        }
    }
}

// MARK: - Timezone Stat

struct TimezoneStat: Codable, Identifiable, Equatable {
    let id: String // timezone name
    let timezone: String
    let count: Int
}

// MARK: - Monthly Count (shared by device model and iOS version history)

struct MonthlyCount: Codable, Identifiable, Equatable {
    var id: String { month }
    let month: String
    let count: Int
    let total: Int

    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total) * 100
    }

    var dateValue: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.date(from: month)
    }
}

typealias DeviceModelMonthlyCount = MonthlyCount
typealias IOSVersionMonthlyCount = MonthlyCount

// MARK: - Device Model History

struct DeviceModelHistoryResponse: Codable, Equatable {
    let modelName: String
    let history: [MonthlyCount]

    enum CodingKeys: String, CodingKey {
        case modelName = "model_name"
        case history
    }
}

// MARK: - iOS Version History

struct IOSVersionHistoryResponse: Codable, Equatable {
    let majorVersion: String
    let history: [MonthlyCount]

    enum CodingKeys: String, CodingKey {
        case majorVersion = "major_version"
        case history
    }
}

// MARK: - iOS Version Device Breakdown

struct IOSVersionDeviceBreakdownResponse: Codable, Equatable {
    let majorVersion: String
    let devices: [IOSVersionDeviceHistory]

    enum CodingKeys: String, CodingKey {
        case majorVersion = "major_version"
        case devices
    }
}

struct IOSVersionDeviceHistory: Codable, Identifiable, Equatable {
    var id: String { modelName }
    let modelName: String
    let history: [IOSVersionDeviceMonthlyCount]

    enum CodingKeys: String, CodingKey {
        case modelName = "model_name"
        case history
    }
}

struct IOSVersionDeviceMonthlyCount: Codable, Identifiable, Equatable {
    var id: String { month }
    let month: String
    let count: Int

    var dateValue: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.date(from: month)
    }
}
