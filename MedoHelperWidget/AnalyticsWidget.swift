//
//  AnalyticsWidget.swift
//  MedoHelperWidget
//
//  Created by Rafael Schmitt on 02/03/26.
//

import SwiftUI
import WidgetKit

struct AnalyticsWidget: Widget {

    let kind = "AnalyticsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AnalyticsProvider()) { entry in
            AnalyticsWidgetView(entry: entry)
                .environment(\.colorScheme, .dark)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [
                            Color(red: 0.04, green: 0.15, blue: 0.08),
                            Color(red: 0.08, green: 0.22, blue: 0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Estatisticas")
        .description("Metricas do Medo e Delirio em tempo real.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

#Preview(as: .systemMedium) {
    AnalyticsWidget()
} timeline: {
    AnalyticsEntry.placeholder
}

#Preview(as: .systemLarge) {
    AnalyticsWidget()
} timeline: {
    AnalyticsEntry.placeholder
}
