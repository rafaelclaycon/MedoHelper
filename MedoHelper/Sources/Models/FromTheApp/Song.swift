//
//  Song.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 23/05/23.
//

import Foundation

struct Song: Hashable, Codable, Identifiable, CustomDebugStringConvertible {

    let id: String
    var title: String
    var description: String
    let genreId: String
    let duration: Double
    let filename: String
    var dateAdded: Date?
    var isOffensive: Bool
    var isFromServer: Bool?

    static let undefinedGenreId: String = "16B61F20-5D24-429F-8751-55F62DBB8DA8"

    init(
        id: String = UUID().uuidString,
        title: String,
        description: String = "",
        genreId: String = Song.undefinedGenreId,
        duration: Double = 0,
        filename: String = "",
        dateAdded: Date = Date(),
        isOffensive: Bool = false,
        isFromServer: Bool? = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.genreId = genreId
        self.duration = duration
        self.filename = filename
        self.dateAdded = dateAdded
        self.isOffensive = isOffensive
        self.isFromServer = isFromServer
    }
    
    var debugDescription: String {
        return self.title
    }
}
