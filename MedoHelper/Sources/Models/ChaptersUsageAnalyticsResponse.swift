//
//  ChaptersUsageAnalyticsResponse.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 15/08/26.
//

import Foundation

struct ChaptersUsageAnalyticsResponse: Codable, Equatable {
    let dailyChapterTapsLast30Days: [ChaptersDailyCount]
    let tapCountEpisodeDetail: Int
    let tapCountNowPlaying: Int
    let previousCount: Int
    let nextCount: Int
    let loadedCount: Int
    let loadFailedCount: Int
    let loadFailedFileMissingCount: Int
    let loadFailedDecodeFailedCount: Int
    let loadFailedNoEntryCount: Int
    let loadFailedEmptyListCount: Int
    let hiddenCount: Int
    let issueReportedCount: Int
    let topChapters: [TopChapter]

    var tapCount: Int { tapCountEpisodeDetail + tapCountNowPlaying }

    var loadSuccessRate: Double {
        let total = loadedCount + loadFailedCount
        guard total > 0 else { return 0 }
        return Double(loadedCount) / Double(total)
    }
}

struct ChaptersDailyCount: Codable, Identifiable, Equatable {
    var id: String { date }
    let date: String
    let tapCount: Int

    var dateValue: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
}

struct TopChapter: Codable, Identifiable, Equatable {
    var id: Int
    let title: String
    let tapCount: Int
}
