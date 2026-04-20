//
//  PodcastEpisode.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 04/04/26.
//

import Foundation

struct PodcastEpisode: Identifiable, Equatable {
    let id: String
    let title: String
    let pubDate: Date?
    var isTranscribed: Bool = false
}
