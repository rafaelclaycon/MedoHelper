//
//  ExternalLink.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 26/03/24.
//

import Foundation

struct ExternalLink: Hashable, Codable, Identifiable {

    var id: String
    var symbol: String
    var title: String
    var color: String
    var link: String

    init(
        id: String = UUID().uuidString,
        symbol: String = "",
        title: String = "",
        color: String = "",
        link: String = ""
    ) {
        self.id = id
        self.symbol = symbol
        self.title = title
        self.color = color
        self.link = link
    }
}
