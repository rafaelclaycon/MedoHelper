//
//  Reaction.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 01/05/24.
//

import Foundation

struct ReactionDTO: Codable, Identifiable {

    let id: String
    let title: String
    let position: Int
    let image: String
    let lastUpdate: String
    let sounds: [ReactionSound]

    init(
        id: String,
        title: String,
        position: Int,
        image: String,
        lastUpdate: String,
        sounds: [ReactionSound]
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
        self.sounds = []
    }
}

struct AppReaction: Codable, Identifiable {

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
}
