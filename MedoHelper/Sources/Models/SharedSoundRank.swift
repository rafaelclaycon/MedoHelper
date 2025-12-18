//
//  SharedSoundRank.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 22/11/25.
//

import Foundation

struct SharedSoundRank: Codable, Identifiable, Equatable {
    let id: String
    let soundId: String
    let soundName: String
    let authorName: String
    let shareCount: Int
    let rank: Int
}

