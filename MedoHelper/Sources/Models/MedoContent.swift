//
//  MedoContent.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 30/04/23.
//

import Foundation

struct MedoContent: Codable {
    
    let id: UUID
    let title: String
    let authorId: String
    let description: String
    let fileId: String
    let creationDate: String
    let duration: Double
    let isOffensive: Bool
    let musicGenre: MusicGenre?
    let contentType: ContentType
    
    init(
        id: UUID,
        title: String,
        authorId: String,
        description: String,
        fileId: String,
        creationDate: String,
        duration: Double,
        isOffensive: Bool,
        musicGenre: MusicGenre?,
        contentType: ContentType
    ) {
        self.id = id
        self.title = title
        self.authorId = authorId
        self.description = description
        self.fileId = fileId
        self.creationDate = creationDate
        self.duration = duration
        self.isOffensive = isOffensive
        self.musicGenre = musicGenre
        self.contentType = contentType
    }
    
    init(
        sound: Sound,
        authorId: String,
        duration: Double
    ) {
        self.id = UUID(uuidString: sound.id)!
        self.title = sound.title
        self.authorId = authorId
        self.description = sound.description
        self.fileId = sound.filename
        self.creationDate = Date.now.toISO8601String()
        self.duration = duration
        self.isOffensive = sound.isOffensive
        self.musicGenre = nil
        self.contentType = .sound
    }
}
