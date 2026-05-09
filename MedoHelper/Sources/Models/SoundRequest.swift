//
//  SoundRequest.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 19/04/26.
//

import Foundation

struct SoundRequest: Identifiable, Codable, Equatable, Hashable {

    let id: String
    var title: String
    var requesterName: String
    var status: SoundRequestStatus
    /// When the user actually received the e-mail from the requester.
    var emailReceivedAt: Date
    /// When the request was entered into the app. Subtract `emailReceivedAt`
    /// to measure how long it took to log the request (future happiness metric).
    let createdAt: Date
    var fulfilledAt: Date?

    init(
        id: String = UUID().uuidString,
        title: String,
        requesterName: String,
        status: SoundRequestStatus = .unfulfilled,
        emailReceivedAt: Date = .now,
        createdAt: Date = .now,
        fulfilledAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.requesterName = requesterName
        self.status = status
        self.emailReceivedAt = emailReceivedAt
        self.createdAt = createdAt
        self.fulfilledAt = fulfilledAt
    }

    /// How long it took the operator to log this request after the e-mail arrived.
    var responseDelay: TimeInterval {
        createdAt.timeIntervalSince(emailReceivedAt)
    }
}

enum SoundRequestStatus: String, Codable, CaseIterable, Identifiable, Hashable {

    case unfulfilled
    case fulfilled

    var id: String { rawValue }

    var label: String {
        switch self {
        case .unfulfilled: return "Pendente"
        case .fulfilled: return "Atendido"
        }
    }

    var systemImage: String {
        switch self {
        case .unfulfilled: return "circle"
        case .fulfilled: return "checkmark.circle.fill"
        }
    }
}
