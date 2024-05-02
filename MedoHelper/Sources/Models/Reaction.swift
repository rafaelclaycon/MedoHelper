//
//  Reaction.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 01/05/24.
//

import Foundation

struct Reaction: Codable, Identifiable {

    let id: UUID
    let title: String
    let position: Int
    let image: String
    let blackOverlay: Int
    let titleSize: Int
    let lastUpdate: String

    init(
        id: UUID,
        title: String,
        position: Int,
        image: String,
        blackOverlay: Int,
        titleSize: Int,
        lastUpdate: String
    ) {
        self.id = id
        self.title = title
        self.position = position
        self.image = image
        self.blackOverlay = blackOverlay
        self.titleSize = titleSize
        self.lastUpdate = lastUpdate
    }

    init(
        position: Int,
        title: String
    ) {
        self.id = UUID()
        self.title = title
        self.position = position
        self.image = ""
        self.blackOverlay = 0
        self.titleSize = 0
        self.lastUpdate = ""
    }
}
