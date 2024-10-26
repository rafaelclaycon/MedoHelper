//
//  ReactionSound.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 12/05/24.
//

import Foundation

/// For fetching Reaction Sounds.
struct ServerReactionSound: Identifiable, Codable, Equatable {

    let id: String
    let soundId: String
    var dateAdded: String
    let position: Int

    enum CodingKeys: String, CodingKey {
        case id, soundId, dateAdded, position
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? "default-id"
        soundId = try container.decode(String.self, forKey: .soundId)
        dateAdded = try container.decode(String.self, forKey: .dateAdded)
        position = try container.decode(Int.self, forKey: .position)
    }

    init(
        id: String?,
        soundId: String,
        dateAdded: String,
        position: Int
    ) {
        self.id = soundId
        self.soundId = soundId
        self.dateAdded = dateAdded
        self.position = position
    }

    init(
        soundId: String,
        dateAdded: String,
        position: Int
    ) {
        self.id = soundId
        self.soundId = soundId
        self.dateAdded = dateAdded
        self.position = position
    }
}

/// Reaction Sounds as they exist on the server.
/// Includes reactionId and excludes object id because that's how we guarantee new records are created on the server.
struct ServerReactionSoundForSending: Codable {

    let soundId: String
    let dateAdded: String
    let position: Int
    let reactionId: String

    init(
        soundId: String,
        dateAdded: String,
        position: Int,
        reactionId: String
    ) {
        self.soundId = soundId
        self.dateAdded = dateAdded
        self.position = position
        self.reactionId = reactionId
    }

    init(
        reactionSound: ServerReactionSound,
        reactionId: String
    ) {
        self.soundId = reactionSound.soundId
        self.dateAdded = reactionSound.dateAdded
        self.position = reactionSound.position
        self.reactionId = reactionId
    }
}

/// Useful for display inside the app since it has Sound title and Author name.
struct ReactionSoundForDisplay: Identifiable, Codable, Hashable {

    let id: String
    let soundId: String
    var title: String
    var authorName: String
    let dateAdded: String
    var position: Int

    init(
        id: String?,
        soundId: String,
        title: String,
        authorName: String,
        dateAdded: String,
        position: Int
    ) {
        self.id = soundId
        self.soundId = soundId
        self.title = title
        self.authorName = authorName
        self.dateAdded = dateAdded
        self.position = position
    }

    init(
        reactionSound: ServerReactionSound
    ) {
        self.id = reactionSound.id
        self.soundId = reactionSound.soundId
        self.title = ""
        self.authorName = ""
        self.dateAdded = reactionSound.dateAdded
        self.position = reactionSound.position
    }
}

extension Array where Element == ReactionSoundForDisplay {

    var asBasicType: [ServerReactionSound] {
        return self.map { displayItem in
            ServerReactionSound(
                id: displayItem.id,
                soundId: displayItem.soundId,
                dateAdded: displayItem.dateAdded,
                position: displayItem.position
            )
        }
    }

    func asServerCompatibleType(reactionId: String) -> [ServerReactionSoundForSending] {
        return self.map { displayItem in
            ServerReactionSoundForSending(
                soundId: displayItem.soundId,
                dateAdded: displayItem.dateAdded,
                position: displayItem.position,
                reactionId: reactionId
            )
        }
    }
}
