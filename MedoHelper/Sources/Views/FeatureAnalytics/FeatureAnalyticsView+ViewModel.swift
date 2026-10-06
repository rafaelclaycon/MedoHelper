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

        var id: String { rawValue }

        var label: String {
            switch self {
            case .today: return "Hoje"
            case .last24Hours: return "Últimas 24h"
            case .last7Days: return "Últimos 7 dias"
            }
        }

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
            }
        }
    }

    @MainActor
    @Observable
    final class ViewModel {

        var period: Period = .today
        var electionLive: LoadingState<ElectionLiveAnalyticsResponse> = .loading
        var lastUpdated: Date?

        /// Period of the numbers on screen, so coming back to the tab keeps them while
        /// refreshing, and only a new period shows the spinner.
        private var loadedPeriod: Period?

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
                if case .loaded = electionLive { return }
                electionLive = .error(error.localizedDescription)
            }
        }
    }
}

extension TimeZone {
    static let brasilia = TimeZone(identifier: "America/Sao_Paulo")!
}
