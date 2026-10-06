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

/// The same usage as a time series for charts, in buckets of a few minutes
/// (`GET v4/election-live-analytics/series`). Same events and undercount as
/// `ElectionLiveAnalyticsResponse`.
struct ElectionLiveSeriesResponse: Codable, Equatable {
    /// Window start, rounded down to a bucket boundary (ISO 8601 UTC).
    let since: String
    let until: String
    let bucketMinutes: Int
    let uniqueStarters: Int
    let totalStarts: Int
    let uniqueStoppers: Int
    /// Every bucket of the window in order, empty ones included.
    let buckets: [ElectionLiveSeriesBucket]
    let generatedAt: String
}

struct ElectionLiveSeriesBucket: Codable, Identifiable, Equatable {
    var id: String { start }
    /// Bucket start, ISO 8601 UTC.
    let start: String
    /// The same instant as "HH:mm" in Brasília time.
    let startBrasilia: String
    let starters: Int
    let newStarters: Int
    /// Everyone who started so far in the window.
    let cumulativeStarters: Int
    let stoppers: Int
    /// Installs whose latest banner event is a start at most 8 hours old at the end of
    /// the bucket. An estimate.
    let watchingEstimate: Int

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    var date: Date? {
        Self.isoFormatter.date(from: start) ?? ISO8601DateFormatter().date(from: start)
    }
}
