//
//  MedoContent.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 30/04/23.
//

import Foundation

struct MedoContent: Codable {
    
    let title: String
    let authorId: String
    let description: String
    let fileId: String
    let creationDate: String
    let duration: Double
    let isOffensive: Bool
    
    init(
        title: String,
        authorId: String,
        description: String,
        fileId: String,
        creationDate: String,
        duration: Double,
        isOffensive: Bool
    ) {
        self.title = title
        self.authorId = authorId
        self.description = description
        self.fileId = fileId
        self.creationDate = creationDate
        self.duration = duration
        self.isOffensive = isOffensive
    }
    
    init(sound: ProtoSound, authorId: String) {
        self.title = sound.title
        self.authorId = authorId
        self.description = sound.description
        self.fileId = sound.filename
        self.creationDate = Date.now.toISO8601String()
        self.duration = 0.0
        self.isOffensive = sound.isOffensive
    }
}
