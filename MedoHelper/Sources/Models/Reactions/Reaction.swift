//
//  Reaction.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 01/05/24.
//

import Foundation

struct HelperReaction: Codable, Identifiable {

    var id: String
    var title: String
    var position: Int
    var image: String
    var lastUpdate: String
    var sounds: [ServerReactionSound]?

    init(
        id: String,
        title: String,
        position: Int,
        image: String,
        lastUpdate: String,
        sounds: [ServerReactionSound]? = nil
    ) {
        self.id = id
        self.title = title
        self.position = position
        self.image = image
        self.lastUpdate = lastUpdate
        self.sounds = sounds
    }

    init(
        position: Int,
        title: String
    ) {
        self.id = UUID().uuidString
        self.title = title
        self.position = position
        self.image = ""
        self.lastUpdate = ""
        self.sounds = nil
    }

    init(
        serverReaction: ServerReaction
    ) {
        self.id = serverReaction.id
        self.title = serverReaction.title
        self.position = serverReaction.position
        self.image = serverReaction.image
        self.lastUpdate = serverReaction.lastUpdate
        self.sounds = nil
    }
}

struct ServerReaction: Codable, Identifiable {

    let id: String
    let title: String
    let position: Int
    let image: String
    let lastUpdate: String

    init(
        id: String,
        title: String,
        position: Int,
        image: String,
        lastUpdate: String
    ) {
        self.id = id
        self.title = title
        self.position = position
        self.image = image
        self.lastUpdate = lastUpdate
    }

    init(
        position: Int,
        title: String
    ) {
        self.id = UUID().uuidString
        self.title = title
        self.position = position
        self.image = ""
        self.lastUpdate = ""
    }

    init(
        helperReaction: HelperReaction
    ) {
        self.id = helperReaction.id
        self.title = helperReaction.title
        self.position = helperReaction.position
        self.image = helperReaction.image
        self.lastUpdate = helperReaction.lastUpdate
    }
}
