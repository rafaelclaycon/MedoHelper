//
//  AnalyticsEntry.swift
//  MedoHelperWidget
//
//  Created by Rafael Schmitt on 02/03/26.
//

import WidgetKit

struct AnalyticsEntry: TimelineEntry {
    let date: Date

    let activeUsersCurrentHour: Int?
    let activeUsersToday: Int?
    let mostUsedVersion: String?
    let mostUsedVersionUsers: Int?
    let episodeActiveUsers: Int?
    let mostSharedSoundName: String?
    let mostSharedSoundAuthor: String?
    let mostSharedSoundCount: Int?
    let mostOpenedReactionTitle: String?

    static var placeholder: AnalyticsEntry {
        AnalyticsEntry(
            date: Date(),
            activeUsersCurrentHour: 42,
            activeUsersToday: 318,
            mostUsedVersion: "7.1",
            mostUsedVersionUsers: 210,
            episodeActiveUsers: 85,
            mostSharedSoundName: "Eita Giovanna",
            mostSharedSoundAuthor: "Giovanna",
            mostSharedSoundCount: 15,
            mostOpenedReactionTitle: "Risadas"
        )
    }
}
