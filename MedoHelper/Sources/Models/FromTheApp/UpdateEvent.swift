//
//  UpdateEvent.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 27/08/23.
//

import Foundation

struct UpdateEvent: Hashable, Codable, Identifiable {

    let id: UUID
    let contentId: String
    let dateTime: String
    let mediaType: MediaType
    let eventType: EventType
    var didSucceed: Bool?

    init(
        id: UUID = UUID(),
        contentId: String,
        dateTime: String,
        mediaType: MediaType,
        eventType: EventType,
        didSucceed: Bool? = nil
    ) {
        self.id = id
        self.contentId = contentId
        self.dateTime = dateTime
        self.mediaType = mediaType
        self.eventType = eventType
        self.didSucceed = didSucceed
    }
}

enum MediaType: Int, Codable {

    case sound, author, song
}

enum EventType: Int, Codable {

    case created, metadataUpdated, fileUpdated, deleted
}
