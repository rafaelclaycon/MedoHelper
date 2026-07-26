//
//  ContentListItem.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 26/07/26.
//

import Foundation

/// Unifies `Sound` and `Song` so both can be listed in a single table.
enum ContentListItem: Identifiable, Hashable {

    case sound(Sound)
    case song(Song)

    var id: String {
        switch self {
        case .sound(let sound): return sound.id
        case .song(let song): return song.id
        }
    }

    var title: String {
        switch self {
        case .sound(let sound): return sound.title
        case .song(let song): return song.title
        }
    }

    var description: String {
        switch self {
        case .sound(let sound): return sound.description
        case .song(let song): return song.description
        }
    }

    var dateAdded: Date? {
        switch self {
        case .sound(let sound): return sound.dateAdded
        case .song(let song): return song.dateAdded
        }
    }

    var duration: Double {
        switch self {
        case .sound(let sound): return sound.duration
        case .song(let song): return song.duration
        }
    }

    var isOffensive: Bool {
        switch self {
        case .sound(let sound): return sound.isOffensive
        case .song(let song): return song.isOffensive
        }
    }

    var contentType: ContentType {
        switch self {
        case .sound: return .sound
        case .song: return .song
        }
    }

    var typeDisplayName: String {
        switch self {
        case .sound: return "Som"
        case .song: return "Música"
        }
    }

    /// Author name for sounds, genre id for songs — whatever the type-specific column shows.
    var secondaryInfo: String {
        switch self {
        case .sound(let sound): return sound.authorName ?? ""
        case .song(let song): return song.genreId
        }
    }

    var sound: Sound? {
        if case .sound(let sound) = self { return sound }
        return nil
    }

    var song: Song? {
        if case .song(let song) = self { return song }
        return nil
    }
}
