//
//  FolderResearchAnalyticsResponse.swift
//  MedoHelper
//
//  Created by Claude on 21/08/26.
//

import Foundation

struct FolderResearchAnalyticsResponse: Codable, Equatable {
    let totalUsers: Int
    let totalFolders: Int
    let totalContentItems: Int
    let topFolderNames: [FolderResearchNamedCount]
    let topEmojis: [FolderResearchNamedCount]
    let topBackgroundColors: [FolderResearchNamedCount]
    let users: [FolderResearchUser]
}

struct FolderResearchNamedCount: Codable, Identifiable, Equatable {
    var id: String { name }
    let name: String
    let count: Int
}

struct FolderResearchUser: Codable, Identifiable, Equatable {
    var id: String { installId }
    let installId: String
    let folderCount: Int
    let contentCount: Int
    let lastActivity: String
    let devices: [FolderResearchDevice]
    let folders: [FolderResearchFolder]

    var lastActivityDate: Date? { FolderResearchDateParsing.date(from: lastActivity) }
}

struct FolderResearchDevice: Codable, Identifiable, Equatable {
    var id: String { modelName + firstSeen }
    let modelName: String
    let firstSeen: String
    let lastSeen: String

    var firstSeenDate: Date? { FolderResearchDateParsing.date(from: firstSeen) }
    var lastSeenDate: Date? { FolderResearchDateParsing.date(from: lastSeen) }
}

struct FolderResearchFolder: Codable, Identifiable, Equatable {
    var id: String { folderId }
    let folderId: String
    let name: String
    let symbol: String
    let backgroundColor: String
    let contentCount: Int
    let createdAt: String
    let lastUpdated: String
    let changeCount: Int
    /// Every snapshot timestamp for this folder, sorted oldest-first.
    let history: [String]
    let contents: [FolderResearchContent]

    var createdAtDate: Date? { FolderResearchDateParsing.date(from: createdAt) }
    var lastUpdatedDate: Date? { FolderResearchDateParsing.date(from: lastUpdated) }
    var historyDates: [Date] { history.compactMap(FolderResearchDateParsing.date) }
}

struct FolderResearchContent: Codable, Identifiable, Equatable {
    var id: String { contentId }
    let contentId: String
    let title: String
    let contentType: String
    let authorName: String?

    var isSound: Bool { contentType == "sound" }
}

/// Server timestamps arrive as ISO 8601 strings with fractional seconds. `APIClient.get`
/// doesn't set a date decoding strategy (other analytics responses follow the same
/// string-plus-computed-property pattern, e.g. `ChaptersDailyCount.dateValue`), so dates
/// here are kept as raw strings and parsed on demand instead.
enum FolderResearchDateParsing {

    static func date(from iso: String) -> Date? {
        withFractionalSeconds.date(from: iso) ?? withoutFractionalSeconds.date(from: iso)
    }

    private static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let withoutFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
