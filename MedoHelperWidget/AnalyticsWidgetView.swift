//
//  AnalyticsWidgetView.swift
//  MedoHelperWidget
//
//  Created by Rafael Schmitt on 02/03/26.
//

import SwiftUI
import WidgetKit

struct AnalyticsWidgetView: View {

    let entry: AnalyticsEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        default:
            mediumView
        }
    }

    // MARK: - Medium Layout (3x2 grid)

    private var mediumView: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 8) {
            GridRow {
                compactMetric(
                    icon: "person.fill",
                    label: "Agora",
                    value: formatted(entry.activeUsersCurrentHour),
                    color: .orange
                )
                compactMetric(
                    icon: "person.2.fill",
                    label: "Hoje",
                    value: formatted(entry.activeUsersToday),
                    color: .blue
                )
                compactMetric(
                    icon: "app.badge.fill",
                    label: "Versao",
                    value: entry.mostUsedVersion ?? "--",
                    color: .purple
                )
            }
            GridRow {
                compactMetric(
                    icon: "play.circle.fill",
                    label: "Episodes",
                    value: formatted(entry.episodeActiveUsers),
                    color: .green
                )
                compactMetric(
                    icon: "square.and.arrow.up.fill",
                    label: "Som",
                    value: entry.mostSharedSoundName.map { truncate($0, to: 10) } ?? "--",
                    color: .pink
                )
                compactMetric(
                    icon: "face.smiling.fill",
                    label: "Reacao",
                    value: entry.mostOpenedReactionTitle.map { truncate($0, to: 10) } ?? "--",
                    color: .yellow
                )
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Large Layout

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Medo e Delirio")
                .font(.headline)
                .foregroundStyle(.secondary)

            Divider()

            detailRow(
                icon: "person.fill",
                label: "Usuarios Agora",
                value: formatted(entry.activeUsersCurrentHour),
                color: .orange
            )

            detailRow(
                icon: "person.2.fill",
                label: "Usuarios Hoje",
                value: formatted(entry.activeUsersToday),
                color: .blue
            )

            detailRow(
                icon: "app.badge.fill",
                label: "Versao Mais Usada",
                value: versionDetail,
                color: .purple
            )

            detailRow(
                icon: "play.circle.fill",
                label: "Episodes Hoje",
                value: formatted(entry.episodeActiveUsers) + " usuarios",
                color: .green
            )

            detailRow(
                icon: "square.and.arrow.up.fill",
                label: "Som Mais Compartilhado",
                value: soundDetail,
                color: .pink
            )

            detailRow(
                icon: "face.smiling.fill",
                label: "Reacao Mais Aberta",
                value: entry.mostOpenedReactionTitle ?? "--",
                color: .yellow
            )

            Spacer(minLength: 0)

            HStack {
                Spacer()
                Text(formattedTime(entry.date))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    // MARK: - Components

    private func compactMetric(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text(value)
                .font(.system(.callout, design: .rounded, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func detailRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Formatting

    private var versionDetail: String {
        guard let version = entry.mostUsedVersion else { return "--" }
        if let users = entry.mostUsedVersionUsers {
            return "\(version) (\(users) usuarios)"
        }
        return version
    }

    private var soundDetail: String {
        guard let name = entry.mostSharedSoundName else { return "--" }
        if let author = entry.mostSharedSoundAuthor {
            return "\(name) - \(author)"
        }
        return name
    }

    private func formatted(_ value: Int?) -> String {
        guard let value else { return "--" }
        return "\(value)"
    }

    private func truncate(_ text: String, to length: Int) -> String {
        if text.count <= length { return text }
        return String(text.prefix(length)) + "..."
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "Atualizado: " + formatter.string(from: date)
    }
}
