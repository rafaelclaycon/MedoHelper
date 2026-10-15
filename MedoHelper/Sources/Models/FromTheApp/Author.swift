//
//  Author.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 25/05/22.
//

import Foundation

struct Author: Hashable, Codable, Identifiable, CustomDebugStringConvertible {

    var id: String
    var name: String
    var photo: String?
    var description: String?
    var externalLinks: String?
    /// Position in the app's row of favorite profile photos, from 1. Nil when not in the
    /// row. The server takes 0 on update to remove an author from the row.
    var featuredRank: Int?

    init(
        id: String = UUID().uuidString,
        name: String,
        photo: String? = nil,
        description: String? = nil,
        externalLinks: String? = nil,
        featuredRank: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.photo = photo
        self.description = description
        self.externalLinks = externalLinks
        self.featuredRank = featuredRank
    }

    var debugDescription: String {
        return self.name
    }
}
