//
//  ElectionLiveAnalyticsResponse.swift
//  MedoHelper
//
//  Created by Claude on 04/10/26.
//

import Foundation

/// Usage of the election Live Activity ("Apuração ao Vivo"), from the events the app's
/// election banner sends. People are counted by install, so starting several times
/// counts once.
///
/// Undercounts: the app only reports a start after the Live Activity actually began,
/// and the results screen (13.1) doesn't send events at all.
struct ElectionLiveAnalyticsResponse: Codable, Equatable {
    let since: String
    let uniqueStarters: Int
    let totalStarts: Int
    let uniqueStoppers: Int
    let totalStops: Int
    /// Installs whose latest banner event in the last 8 hours is a start. An estimate.
    let likelyWatchingNow: Int
    let whatsNewDismissals: Int
    let hourly: [ElectionLiveHourlyCount]
    let startersByVersion: [ElectionLiveVersionCount]
    let generatedAt: String
}

struct ElectionLiveHourlyCount: Codable, Identifiable, Equatable {
    var id: String { hour }
    /// UTC hour, `yyyy-MM-ddTHH`.
    let hour: String
    let starters: Int
    /// Installs whose first start in the window was in this hour.
    let newStarters: Int
    let stoppers: Int

    private static let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    var date: Date? {
        Self.hourFormatter.date(from: hour)
    }
}

struct ElectionLiveVersionCount: Codable, Identifiable, Equatable {
    var id: String { appVersion }
    let appVersion: String
    let starters: Int
}
