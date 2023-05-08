//
//  Sound.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 25/05/22.
//

import Foundation

struct Sound: Hashable, Codable, Identifiable {
    
    var id: String
    var title: String
    var authorId: String
    var authorName: String?
    var description: String
    var filename: String
    var dateAdded: Date?
    let duration: Double
    let isOffensive: Bool
    let isNew: Bool?
    let isFromServer: Bool?
    
    init(
        id: String = UUID().uuidString,
        title: String,
        authorId: String = UUID().uuidString,
        description: String = "",
        filename: String = "",
        dateAdded: Date? = Date(),
        duration: Double = 0,
        isOffensive: Bool = false,
        isNew: Bool? = nil,
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
        self.isNew = isNew
        self.isFromServer = isFromServer
    }
}
