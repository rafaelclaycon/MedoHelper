//
//  PushBroadcast.swift
//  MedoHelper
//
//  Created by Claude on 25/10/26.
//

import Foundation

/// A plain alert sent to every device; tapping it just opens the app. Typed pushes
/// (new episode, weekly highlights, content sync) are only sent by the server itself.
struct PushBroadcastRequest: Encodable {
    let title: String
    let body: String
}

struct PushBroadcastStatus: Decodable, Equatable, Identifiable {

    enum State: String, Decodable {
        case sending, finished, cancelled
    }

    let id: UUID
    let title: String
    let body: String
    let state: State
    let total: Int
    let processed: Int
    let sent: Int
    let failed: Int
    let removedTokens: Int
    let startedAt: Date
    let finishedAt: Date?
    let recentErrors: [String]
}

struct PushAudience: Decodable {
    let deviceCount: Int
}
