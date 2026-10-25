//
//  TodayWidgetView.swift
//  MedoHelperWidget
//
//  Created by Claude on 25/10/26.
//

import SwiftUI
import WidgetKit

struct TodayWidgetView: View {

    let entry: TodayEntry

    private static let ptBR = Locale(identifier: "pt_BR")

    private var summary: WidgetSummaryResponse? { entry.summary }

    var body: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            GridRow {
                MetricTile(
                    title: "Usuários",
                    symbol: "person.2.fill",
                    tint: Color(red: 0.42, green: 0.78, blue: 1.0),
                    value: Self.number(summary?.activeUsers.today),
                    change: summary?.activeUsers.changePercent,
                    footnote: summary.map { yesterdayFootnote($0.activeUsers) } ?? Self.noData
                )
                MetricTile(
                    title: "Jogaram",
                    symbol: "gamecontroller.fill",
                    tint: Color(red: 1.0, green: 0.66, blue: 0.3),
                    value: Self.number(summary?.gamePlayers),
                    change: nil,
                    footnote: summary == nil ? Self.noData : "começaram um jogo"
                )
            }
            GridRow {
                MetricTile(
                    title: "Capítulos",
                    symbol: "list.bullet.rectangle.fill",
                    tint: Color(red: 0.42, green: 0.92, blue: 0.68),
                    value: Self.number(summary?.chapterUsers.today),
                    change: summary?.chapterUsers.changePercent,
                    footnote: summary.map { yesterdayFootnote($0.chapterUsers) } ?? Self.noData
                )
                MetricTile(
                    title: "Versão",
                    symbol: "app.badge.fill",
                    tint: Color(red: 0.78, green: 0.64, blue: 1.0),
                    value: summary?.topVersion?.appVersion ?? "--",
                    change: nil,
                    footnote: summary == nil ? Self.noData : summary?.topVersion.map {
                        "\($0.percentage.formatted(.number.precision(.fractionLength(0)).locale(Self.ptBR)))% dos usuários"
                    }
                )
            }
        }
        .padding(11)
    }

    private static let noData = "sem dados"

    /// What the pill compares against: yesterday up to this time of day, not all of it.
    /// Showing the whole day next to a rise would read like a mistake.
    private func yesterdayFootnote(_ comparison: WidgetSummaryResponse.DayComparison) -> String {
        let time = Calendar.current.dateComponents([.hour, .minute], from: entry.date)
        let hour = time.hour ?? 0
        let minute = time.minute ?? 0
        let clock = minute == 0 ? "\(hour)h" : "\(hour)h" + String(format: "%02d", minute)
        return "ontem até \(clock): \(Self.number(comparison.yesterdayUntilNow))"
    }

    private static func number(_ value: Int?) -> String {
        guard let value else { return "--" }
        return value.formatted(.number.locale(ptBR))
    }
}

/// One number with its label, an optional rise-or-fall pill next to it, and a gray line
/// of context underneath.
private struct MetricTile: View {

    let title: String
    let symbol: String
    let tint: Color
    let value: String
    let change: Double?
    let footnote: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(tint)
                    .widgetAccentable()
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText())
                    .layoutPriority(1)

                if let change {
                    ChangeBadge(percent: change)
                }
            }

            if let footnote {
                Text(footnote)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.white.opacity(0.07))
                .strokeBorder(.white.opacity(0.08), lineWidth: 0.5)
        }
    }
}

/// "▲ 8%" in green or "▼ 5%" in red. Under half a percent either way reads as no change.
private struct ChangeBadge: View {

    let percent: Double

    private var rounded: Int { Int(percent.rounded()) }

    private var color: Color {
        if rounded > 0 { return Color(red: 0.3, green: 0.85, blue: 0.45) }
        if rounded < 0 { return Color(red: 1.0, green: 0.42, blue: 0.4) }
        return .white.opacity(0.6)
    }

    private var symbol: String? {
        if rounded > 0 { return "arrowtriangle.up.fill" }
        if rounded < 0 { return "arrowtriangle.down.fill" }
        return nil
    }

    var body: some View {
        HStack(spacing: 2) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 6, weight: .bold))
            }
            Text("\(abs(rounded))%")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
        .foregroundStyle(color)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(color.opacity(0.16), in: Capsule())
        .fixedSize()
        .accessibilityLabel(rounded == 0 ? "igual a ontem" : "\(rounded > 0 ? "subiu" : "caiu") \(abs(rounded))% em relação a ontem")
    }
}
