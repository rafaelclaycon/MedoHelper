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
    var attributionText: String
    var attributionURL: String
    var sounds: [ServerReactionSound]?

    init(
        id: String,
        title: String,
        position: Int,
        image: String,
        lastUpdate: String,
        attributionText: String,
        attributionURL: String,
        sounds: [ServerReactionSound]? = nil
    ) {
        self.id = id
        self.title = title
        self.position = position
        self.image = image
        self.lastUpdate = lastUpdate
        self.attributionText = attributionText
        self.attributionURL = attributionURL
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
        self.attributionText = ""
        self.attributionURL = ""
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
        self.attributionText = serverReaction.attributionText ?? ""
        self.attributionURL = serverReaction.attributionURL ?? ""
        self.sounds = nil
    }
}

struct ServerReaction: Codable, Identifiable {

    let id: String
    let title: String
    let position: Int
    let image: String
    let lastUpdate: String
    let attributionText: String?
    let attributionURL: String?

    init(
        id: String,
        title: String,
        position: Int,
        image: String,
        lastUpdate: String,
        attributionText: String?,
        attributionURL: String?
    ) {
        self.id = id
        self.title = title
        self.position = position
        self.image = image
        self.lastUpdate = lastUpdate
        self.attributionText = attributionText
        self.attributionURL = attributionURL
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
        self.attributionText = nil
        self.attributionURL = nil
    }

    init(
        helperReaction: HelperReaction
    ) {
        self.id = helperReaction.id
        self.title = helperReaction.title
        self.position = helperReaction.position
        self.image = helperReaction.image
        self.lastUpdate = helperReaction.lastUpdate
        self.attributionText = helperReaction.attributionText
        self.attributionURL = helperReaction.attributionURL
    }
}
