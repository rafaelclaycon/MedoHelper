//
//  MusicGenre.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 26/08/23.
//

import Foundation

struct MusicGenre: Hashable, Codable, Identifiable, CustomDebugStringConvertible {

    let id: String
    var symbol: String
    var name: String
    let isHidden: Bool

    init(
        id: String = UUID().uuidString,
        symbol: String,
        name: String,
        isHidden: Bool = false
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.isHidden = isHidden
    }

    var debugDescription: String {
        return self.name
    }
}
