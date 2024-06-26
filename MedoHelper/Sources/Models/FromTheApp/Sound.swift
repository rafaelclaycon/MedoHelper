//
//  Sound.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 25/05/22.
//

import Foundation

struct Sound: Hashable, Codable, Identifiable, CustomDebugStringConvertible {

    var id: String
    var title: String
    var authorId: String
    var authorName: String?
    var description: String
    var filename: String
    var dateAdded: Date?
    let duration: Double
    var isOffensive: Bool
    let isFromServer: Bool?

    init(
        id: String = UUID().uuidString,
        title: String,
        authorId: String = "",
        description: String = "",
        filename: String = "",
        dateAdded: Date? = Date(),
        duration: Double = 0,
        isOffensive: Bool = false,
        isFromServer: Bool? = false
    ) {
        self.id = id
        self.title = title
        self.authorId = authorId
        self.description = description
        self.filename = filename
        self.dateAdded = dateAdded
        self.duration = duration
        self.isOffensive = isOffensive
        self.isFromServer = isFromServer
    }

    var debugDescription: String {
        return self.title
    }
}

struct SoundDTO: Hashable, Codable, Identifiable {

    var id: String
    var title: String
    var authorId: String
    var authorName: String?
    var description: String
    var filename: String
    var dateAdded: String
    let duration: Double
    var isOffensive: Bool
    let isFromServer: Bool?

    init(
        id: String = UUID().uuidString,
        title: String,
        authorId: String = "",
        description: String = "",
        filename: String = "",
        dateAdded: String,
        duration: Double = 0,
        isOffensive: Bool = false,
        isFromServer: Bool? = false
    ) {
        self.id = id
        self.title = title
        self.authorId = authorId
        self.description = description
        self.filename = filename
        self.dateAdded = dateAdded
        self.duration = duration
        self.isOffensive = isOffensive
        self.isFromServer = isFromServer
    }
}
