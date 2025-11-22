//
//  Analytics.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 22/11/25.
//

import Foundation

struct Analytics: Codable {
    let activeUsers: Int
    let sessions: Int
    let topSharedSounds: [SharedSoundRank]
}

