//
//  ShareClipAnalyticsResponse.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 02/08/26.
//

import Foundation

struct ShareClipAnalyticsResponse: Codable, Equatable {
    let dailySharesLast30Days: [ShareClipDailyCount]
    let tapCount: Int
    let sharedCount: Int
    let sharedWithTranscriptCount: Int
    let sharedWithoutTranscriptCount: Int
    let generationFailedCount: Int
    let supportPromptShownCount: Int
    let whatsNewDismissedCount: Int
    let conversionRate: Double
}

struct ShareClipDailyCount: Codable, Identifiable, Equatable {
    var id: String { date }
    let date: String
    let activeUsers: Int

    var dateValue: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
}
