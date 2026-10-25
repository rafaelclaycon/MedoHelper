//
//  TodayWidget.swift
//  MedoHelperWidget
//
//  Created by Claude on 25/10/26.
//

import SwiftUI
import WidgetKit

struct TodayEntry: TimelineEntry {
    let date: Date
    /// Nil when the server couldn't be reached; the view shows dashes.
    let summary: WidgetSummaryResponse?

    static var placeholder: TodayEntry {
        TodayEntry(
            date: .now,
            summary: WidgetSummaryResponse(
                day: "2026-10-25",
                activeUsers: .init(today: 12_480, yesterday: 15_210, yesterdayUntilNow: 11_530),
                chapterUsers: .init(today: 1_342, yesterday: 1_890, yesterdayUntilNow: 1_410),
                gamePlayers: 2_317,
                topVersion: .init(appVersion: "13.6", uniqueUsers: 7_740, percentage: 62.0)
            )
        )
    }
}

struct TodayProvider: TimelineProvider {

    func placeholder(in context: Context) -> TodayEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        Task {
            completion(TodayEntry(date: .now, summary: await WidgetDataFetcher.fetchSummary()))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        Task {
            let entry = TodayEntry(date: .now, summary: await WidgetDataFetcher.fetchSummary())
            completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(15 * 60))))
        }
    }
}

struct TodayWidget: Widget {

    let kind = "TodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayProvider()) { entry in
            TodayWidgetView(entry: entry)
                .environment(\.colorScheme, .dark)
                .containerBackground(for: .widget) {
                    TodayWidgetBackground()
                }
        }
        .configurationDisplayName("Hoje")
        .description("Usuários, jogos, capítulos e a versão mais usada hoje. As porcentagens comparam com ontem até este horário.")
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

/// Deep green, like the other widget, with a soft glow in the top corner.
struct TodayWidgetBackground: View {

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.13, blue: 0.08),
                    Color(red: 0.02, green: 0.07, blue: 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Color(red: 0.16, green: 0.62, blue: 0.32).opacity(0.45), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 260
            )
        }
    }
}

#Preview(as: .systemMedium) {
    TodayWidget()
} timeline: {
    TodayEntry.placeholder
    TodayEntry(date: .now, summary: nil)
}
