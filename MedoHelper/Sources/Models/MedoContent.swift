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
    let musicGenre: String?
    let contentType: ContentType
    let isHidden: Bool
    
    init(
        id: UUID,
        title: String,
        authorId: String,
        description: String,
        fileId: String,
        creationDate: String,
        duration: Double,
        isOffensive: Bool,
        musicGenre: String?,
        contentType: ContentType,
        isHidden: Bool
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
        self.isHidden = isHidden
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
        self.creationDate = Date.now.iso8601String
        self.duration = duration
        self.isOffensive = sound.isOffensive
        self.musicGenre = nil
        self.contentType = .sound
        self.isHidden = false
    }

    init(
        song: Song,
        genreId: String,
        duration: Double
    ) {
        self.id = UUID(uuidString: song.id)!
        self.title = song.title
        self.authorId = ""
        self.description = song.description
        self.fileId = song.filename
        self.creationDate = Date.now.iso8601String
        self.duration = duration
        self.isOffensive = song.isOffensive
        self.musicGenre = genreId
        self.contentType = .song
        self.isHidden = false
    }
}
