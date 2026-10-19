//
//  GamesAnalyticsResponse.swift
//  MedoHelper
//
//  Created by Claude on 18/10/26.
//

import Foundation

/// Usage of the games ("De quem é essa fuça?" and "Eu já ouvi essa voz antes…"), from the
/// events the app sends. People are counted by install. Percentages go from 0 to 100.
struct GamesAnalyticsResponse: Codable, Equatable {
    /// Window length in UTC days, today included.
    let days: Int
    let since: String
    /// Distinct installs with a still-alive signal in the window, any version.
    let activeUsers: Int
    /// Active installs on a version with games (13.6 or later). Denominator of
    /// `playerPercentage`.
    let activeUsersWithGames: Int
    /// Distinct installs that started a game.
    let players: Int
    let playerPercentage: Double
    /// Players who started a game on two or more UTC days of the window.
    let returningPlayers: Int
    /// Players who finished at least one game.
    let finishers: Int
    let starts: Int
    let finishes: Int
    let abandons: Int
    /// `finishes / starts * 100`. A game closed with the app sends neither a finish nor an
    /// abandon.
    let completionPercentage: Double
    /// Most players first.
    let games: [GamesAnalyticsGame]
    /// One per UTC day, oldest first.
    let daily: [GamesAnalyticsDay]
    let shares: Int
    let sharesByFormat: [GamesAnalyticsNameCount]
    /// By iOS activity type, at most 10.
    let sharesByDestination: [GamesAnalyticsNameCount]
    let musicMutedCount: Int
    let musicUnmutedCount: Int
    /// Author IDs whose photo failed to load in a round, at most 20.
    let brokenAuthorPhotos: [GamesAnalyticsNameCount]
    let supportSheetShownCount: Int
    let generatedAt: String
}

struct GamesAnalyticsGame: Codable, Identifiable, Equatable {
    var id: String { game }
    /// "whoseFace" or "whoseVoice".
    let game: String
    let players: Int
    let starts: Int
    let finishes: Int
    let abandons: Int
    let completionPercentage: Double
    /// Points in `whoseFace` (about 0 to 10,000), correct answers in `whoseVoice`.
    let averageScore: Double?
    let averageHits: Double?
    /// Average time to answer a round. A high one suggests the game is too hard.
    let averageSecondsPerRound: Double?
    let newRecords: Int
    let hitsDistribution: [GamesAnalyticsHitsCount]
    let abandonsByRound: [GamesAnalyticsRoundCount]
    let shares: Int

    var displayName: String {
        switch game {
        case "whoseFace": return "De quem é essa fuça?"
        case "whoseVoice": return "Eu já ouvi essa voz antes…"
        default: return game
        }
    }

    /// The face game scores points; the voice game counts correct answers.
    var scoresPoints: Bool { game == "whoseFace" }
}

struct GamesAnalyticsHitsCount: Codable, Identifiable, Equatable {
    var id: Int { hits }
    let hits: Int
    let finishes: Int
}

struct GamesAnalyticsRoundCount: Codable, Identifiable, Equatable {
    var id: Int { round }
    let round: Int
    let abandons: Int
    /// Abandons that came after answering the round.
    let answered: Int
}

struct GamesAnalyticsDay: Codable, Identifiable, Equatable {
    var id: String { date }
    /// UTC day, `yyyy-MM-dd`.
    let date: String
    let players: Int
    /// Players whose first start in the window was on this day.
    let newPlayers: Int
    let starts: Int
    let finishes: Int

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .utc
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    /// Midnight UTC. Charts using it need `.environment(\.timeZone, .utc)`.
    var day: Date? { Self.dayFormatter.date(from: date) }
}

struct GamesAnalyticsNameCount: Codable, Identifiable, Equatable {
    var id: String { name }
    let name: String
    let count: Int
}

extension TimeZone {
    static let utc = TimeZone(identifier: "UTC")!
}
