//
//  AnalyticsProvider.swift
//  MedoHelperWidget
//
//  Created by Rafael Schmitt on 02/03/26.
//

import WidgetKit

struct AnalyticsProvider: TimelineProvider {

    func placeholder(in context: Context) -> AnalyticsEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (AnalyticsEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
            return
        }
        Task {
            let entry = await WidgetDataFetcher.fetchAll()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AnalyticsEntry>) -> Void) {
        Task {
            let entry = await WidgetDataFetcher.fetchAll()
            let refreshDate = Date().addingTimeInterval(15 * 60)
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }
}
