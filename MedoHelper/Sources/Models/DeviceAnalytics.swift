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
