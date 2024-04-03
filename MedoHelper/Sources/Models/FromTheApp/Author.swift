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

    init(
        id: String = UUID().uuidString,
        name: String,
        photo: String? = nil,
        description: String? = nil,
        externalLinks: String? = nil
    ) {
        self.id = id
        self.name = name
        self.photo = photo
        self.description = description
        self.externalLinks = externalLinks
    }

    var debugDescription: String {
        return self.name
    }
}
