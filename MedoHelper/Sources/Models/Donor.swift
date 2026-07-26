//
//  Donor.swift
//  MedoHelper
//
//  Created by Claude on 03/07/26.
//

import Foundation

/// A donor as managed locally in the helper app.
///
/// The server model (see `DonorDTO`) only knows `name` + the recurrence/history
/// flags. We keep an extra `id` and `createdAt` locally so the UI can sort by
/// "add date" and keep a stable identity while editing. These local-only fields
/// are stripped out when talking to the server.
struct Donor: Identifiable, Codable, Equatable, Hashable {

    let id: String
    var name: String
    /// Whether this person has donated at least once before.
    var hasDonatedBefore: Bool
    /// Recurring-donation tier. Maps to the two optional server booleans.
    var recurrence: DonorRecurrence
    /// When this donor was added in the app. Used for the "by add date" sort.
    let createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        hasDonatedBefore: Bool = false,
        recurrence: DonorRecurrence = .none,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.hasDonatedBefore = hasDonatedBefore
        self.recurrence = recurrence
        self.createdAt = createdAt
    }
}

// MARK: - Recurrence

/// The recurring-donation tier, modelling the two mutually-exclusive server
/// booleans (`isRecurringDonorBelow30` / `isRecurringDonor30OrOver`) as one
/// pick-one value.
enum DonorRecurrence: String, Codable, CaseIterable, Identifiable, Hashable {

    /// Not a recurring donor. Both server booleans are `nil`.
    case none
    /// Recurring donor giving below 30.
    case below30
    /// Recurring donor giving 30 or over.
    case thirtyOrOver

    var id: String { rawValue }

    var label: String {
        switch self {
        case .none: return "Não recorrente"
        case .below30: return "Recorrente < 30"
        case .thirtyOrOver: return "Recorrente ≥ 30"
        }
    }

    var shortLabel: String {
        switch self {
        case .none: return "—"
        case .below30: return "< 30"
        case .thirtyOrOver: return "≥ 30"
        }
    }
}

// MARK: - Wire Format

/// Exactly the shape the API expects/returns, matching the iOS app's `Donor`.
///
/// ```
/// { "name": "...", "hasDonatedBefore": false, "isRecurringDonorBelow30": true }
/// ```
struct DonorDTO: Codable, Equatable {

    let name: String
    let hasDonatedBefore: Bool
    let isRecurringDonorBelow30: Bool?
    let isRecurringDonor30OrOver: Bool?
}

// MARK: - Conversions

extension Donor {

    /// The server payload for this donor. Only the tier's own flag is sent as
    /// `true`; the other stays `nil`, matching the example JSON.
    var dto: DonorDTO {
        switch recurrence {
        case .none:
            return DonorDTO(
                name: name,
                hasDonatedBefore: hasDonatedBefore,
                isRecurringDonorBelow30: nil,
                isRecurringDonor30OrOver: nil
            )
        case .below30:
            return DonorDTO(
                name: name,
                hasDonatedBefore: hasDonatedBefore,
                isRecurringDonorBelow30: true,
                isRecurringDonor30OrOver: nil
            )
        case .thirtyOrOver:
            return DonorDTO(
                name: name,
                hasDonatedBefore: hasDonatedBefore,
                isRecurringDonorBelow30: nil,
                isRecurringDonor30OrOver: true
            )
        }
    }

    /// Build a local donor from a server payload. `createdAt` is unknown on the
    /// server side, so callers should merge in a locally-remembered date.
    init(dto: DonorDTO, id: String = UUID().uuidString, createdAt: Date = .now) {
        let recurrence: DonorRecurrence
        if dto.isRecurringDonor30OrOver == true {
            recurrence = .thirtyOrOver
        } else if dto.isRecurringDonorBelow30 == true {
            recurrence = .below30
        } else {
            recurrence = .none
        }
        self.init(
            id: id,
            name: dto.name,
            hasDonatedBefore: dto.hasDonatedBefore,
            recurrence: recurrence,
            createdAt: createdAt
        )
    }
}
