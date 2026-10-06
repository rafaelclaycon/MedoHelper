//
//  FeatureAnalyticsView+ViewModel.swift
//  MedoHelper
//
//  Created by Claude on 04/10/26.
//

import SwiftUI

extension FeatureAnalyticsView {

    enum Period: String, CaseIterable, Identifiable {
        case today
        case last24Hours
        case last7Days
        case firstRound
        case secondRound

        var id: String { rawValue }

        var label: String {
            switch self {
            case .today: return "Hoje"
            case .last24Hours: return "Últimas 24h"
            case .last7Days: return "Últimos 7 dias"
            case .firstRound: return "04/10"
            case .secondRound: return "25/10"
            }
        }

        /// Election nights: from the start of the count, 17h in Brasília, to 3h the next day.
        private static let firstRoundStart = Date(timeIntervalSince1970: 1_791_144_000) // 2026-10-04T20:00:00Z
        private static let firstRoundEnd = Date(timeIntervalSince1970: 1_791_180_000) // 2026-10-05T06:00:00Z
        private static let secondRoundStart = Date(timeIntervalSince1970: 1_792_958_400) // 2026-10-25T20:00:00Z
        private static let secondRoundEnd = Date(timeIntervalSince1970: 1_792_994_400) // 2026-10-26T06:00:00Z

        /// "Hoje" starts at midnight in Brasília, regardless of the Mac's time zone.
        func startDate(now: Date = Date()) -> Date {
            switch self {
            case .today:
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = .brasilia
                return calendar.startOfDay(for: now)
            case .last24Hours:
                return now.addingTimeInterval(-24 * 60 * 60)
            case .last7Days:
                return now.addingTimeInterval(-7 * 24 * 60 * 60)
            case .firstRound:
                return Self.firstRoundStart
            case .secondRound:
                return Self.secondRoundStart
            }
        }

        /// The window of the 10-minute series. Nil when it's longer than the 48 hours the
        /// server allows: those periods keep the hourly charts.
        func seriesWindow(now: Date = Date()) -> (since: Date, until: Date)? {
            switch self {
            case .today, .last24Hours:
                return (startDate(now: now), now)
            case .last7Days:
                return nil
            case .firstRound:
                return (Self.firstRoundStart, Self.firstRoundEnd)
            case .secondRound:
                return (Self.secondRoundStart, Self.secondRoundEnd)
            }
        }
    }

    @MainActor
    @Observable
    final class ViewModel {

        var period: Period = .today
        var electionLive: LoadingState<ElectionLiveAnalyticsResponse> = .loading
        /// The 10-minute series for the charts. Nil for periods over 48 hours, and when the
        /// server doesn't have the series yet: the charts then fall back to hourly.
        var electionSeries: ElectionLiveSeriesResponse?
        var lastUpdated: Date?

        /// Period of the numbers on screen, so coming back to the tab keeps them while
        /// refreshing, and only a new period shows the spinner.
        private var loadedPeriod: Period?
        private var seriesPeriod: Period?

        static let seriesBucketMinutes = 10

        /// Election night moves fast, so this refreshes more often than the main tab.
        static let refreshInterval: Duration = .seconds(600)

        private let repository: AnalyticsRepositoryProtocol

        init(repository: AnalyticsRepositoryProtocol = AnalyticsRepository()) {
            self.repository = repository
        }

        /// Reloads until cancelled. Driven by `.task(id: period)`, so changing the period
        /// restarts it right away.
        func refreshPeriodically() async {
            if loadedPeriod != period {
                electionLive = .loading
            }
            if seriesPeriod != period {
                electionSeries = nil
            }
            while !Task.isCancelled {
                await load()
                try? await Task.sleep(for: Self.refreshInterval)
            }
        }

        func onRetry() async {
            electionLive = .loading
            await load()
        }

        private func load() async {
            let period = period
            async let series = loadSeries(for: period)
            do {
                let response = try await repository.fetchElectionLiveAnalytics(since: period.startDate())
                guard !Task.isCancelled else { return }
                electionLive = .loaded(response)
                loadedPeriod = period
                lastUpdated = Date()
            } catch {
                guard !Task.isCancelled else { return }
                print(error)
                // Keep the last good numbers on screen if a periodic refresh fails.
                if case .loaded = electionLive {} else {
                    electionLive = .error(error.localizedDescription)
                }
            }

            let loadedSeries = await series
            guard !Task.isCancelled else { return }
            if let loadedSeries {
                electionSeries = loadedSeries
                seriesPeriod = period
            } else if seriesPeriod != period {
                // Keep the last good series if a refresh fails, but never show another period's.
                electionSeries = nil
            }
        }

        private func loadSeries(for period: Period) async -> ElectionLiveSeriesResponse? {
            guard let window = period.seriesWindow() else { return nil }
            do {
                return try await repository.fetchElectionLiveSeries(
                    since: window.since,
                    until: window.until,
                    bucketMinutes: Self.seriesBucketMinutes
                )
            } catch {
                print(error)
                return nil
            }
        }
    }
}

extension TimeZone {
    static let brasilia = TimeZone(identifier: "America/Sao_Paulo")!
}
