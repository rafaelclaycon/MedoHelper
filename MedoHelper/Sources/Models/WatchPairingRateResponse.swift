//
//  WatchPairingRateResponse.swift
//  MedoHelper
//
//  Created by Claude on 03/09/26.
//

import Foundation

/// Snapshot of how many active users have an Apple Watch paired.
///
/// `percentage` is `watchPairedUsers / eligibleUsers * 100` — the denominator is
/// `eligibleUsers` (active users whose `isWatchPaired` is known), not `activeUsers`.
/// `activeUsers - eligibleUsers` is the slice of the active base that hasn't
/// reported the field yet (iPad/Mac, or an app version older than the collection).
struct WatchPairingRateResponse: Codable, Equatable {
    let activeDays: Int
    let activeUsers: Int
    let eligibleUsers: Int
    let watchPairedUsers: Int
    let percentage: Double
    let generatedAt: String

    /// Active users still missing the `isWatchPaired` data.
    var unknownUsers: Int { max(0, activeUsers - eligibleUsers) }
}
