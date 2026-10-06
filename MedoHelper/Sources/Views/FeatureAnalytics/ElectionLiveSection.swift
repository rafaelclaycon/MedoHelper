//
//  ElectionLiveSection.swift
//  MedoHelper
//
//  Created by Claude on 04/10/26.
//

import SwiftUI
import Charts

private let platterColor = Color.gray.opacity(0.3)
private let sectionTitle = "Apuração ao Vivo"
private let sectionIcon = "dot.radiowaves.left.and.right"
private let sectionColor = Color.green

/// Election Live Activity usage, from the "Acompanhar ao Vivo" banner events.
struct ElectionLiveSection: View {

    let state: LoadingState<ElectionLiveAnalyticsResponse>
    let onRetry: () -> Void

    var body: some View {
        switch state {
        case .loading:
            SectionLoadingView(title: sectionTitle, icon: sectionIcon, color: sectionColor)
        case .loaded(let response):
            ElectionLiveContent(response: response)
        case .error(let message):
            SectionErrorView(title: sectionTitle, icon: sectionIcon, color: sectionColor, message: message, retryAction: onRetry)
        }
    }
}

// MARK: - Content

private struct ElectionLiveContent: View {

    let response: ElectionLiveAnalyticsResponse

    private let cardColumns = [GridItem(.adaptive(minimum: 220), spacing: 12, alignment: .top)]
    private let chartColumns = [GridItem(.adaptive(minimum: 380), spacing: 20, alignment: .top)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: sectionIcon)
                    .foregroundStyle(sectionColor)
                    .font(.title2)
                Text(sectionTitle)
                    .font(.title2.bold())
                Spacer()
            }

            LazyVGrid(columns: cardColumns, alignment: .leading, spacing: 12) {
                EpisodeMiniStatCard(
                    title: "Pessoas que iniciaram",
                    value: response.uniqueStarters.formatted(),
                    subtitle: "\(response.totalStarts.formatted()) inícios",
                    icon: "play.circle.fill",
                    color: .green
                )
                EpisodeMiniStatCard(
                    title: "Provavelmente acompanhando agora",
                    value: response.likelyWatchingNow.formatted(),
                    subtitle: "Estimativa (últimas 8h)",
                    icon: "dot.radiowaves.left.and.right",
                    color: .orange
                )
                EpisodeMiniStatCard(
                    title: "Pessoas que pararam",
                    value: response.uniqueStoppers.formatted(),
                    subtitle: "\(response.totalStops.formatted()) paradas",
                    icon: "stop.circle.fill",
                    color: .red
                )
                EpisodeMiniStatCard(
                    title: "Fecharam a novidade",
                    value: response.whatsNewDismissals.formatted(),
                    subtitle: "Tela de novidades da eleição",
                    icon: "sparkles",
                    color: .purple
                )
            }

            if response.hourly.isEmpty {
                ContentUnavailableView {
                    Label("Nenhum Evento", systemImage: sectionIcon)
                } description: {
                    Text("Ninguém iniciou a Apuração ao Vivo pelo banner neste período.")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(platterColor)
                .cornerRadius(12)
            } else {
                LazyVGrid(columns: chartColumns, alignment: .leading, spacing: 20) {
                    ElectionLiveHourlyChart(hourly: response.hourly)
                    ElectionLiveCumulativeChart(hourly: response.hourly)
                }
            }

            if !response.startersByVersion.isEmpty {
                ElectionLiveVersionList(versions: response.startersByVersion, total: response.uniqueStarters)
            }

            ElectionLiveCaveats()
        }
    }
}

// MARK: - Charts

private enum BrasiliaHourAxis {

    private static let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH'h'"
        formatter.timeZone = .brasilia
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM"
        formatter.timeZone = .brasilia
        return formatter
    }()

    /// Days for windows over two days, hours otherwise, with roughly 8 labels.
    static func marks(for dates: [Date]) -> some AxisContent {
        let spanHours: Int
        if let first = dates.min(), let last = dates.max() {
            spanHours = Int(last.timeIntervalSince(first) / 3600) + 1
        } else {
            spanHours = 1
        }
        let usesDays = spanHours > 48

        return AxisMarks(values: usesDays ? .stride(by: .day) : .stride(by: .hour, count: max(1, spanHours / 8))) { value in
            AxisGridLine()
            AxisTick()
            AxisValueLabel {
                if let date = value.as(Date.self) {
                    Text(usesDays ? dayFormatter.string(from: date) : hourFormatter.string(from: date))
                }
            }
        }
    }
}

private struct ElectionLiveHourlyChart: View {

    let hourly: [ElectionLiveHourlyCount]

    private struct Point: Identifiable {
        let id: String
        let date: Date
        let action: String
        let count: Int
    }

    private var points: [Point] {
        hourly.flatMap { item -> [Point] in
            guard let date = item.date else { return [] }
            return [
                Point(id: item.hour + "-start", date: date, action: "Iniciaram", count: item.starters),
                Point(id: item.hour + "-stop", date: date, action: "Pararam", count: item.stoppers)
            ]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pessoas por hora")
                .font(.headline)
            Text("Horário de Brasília")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart(points) { point in
                BarMark(
                    x: .value("Hora", point.date, unit: .hour),
                    y: .value("Pessoas", point.count)
                )
                .foregroundStyle(by: .value("Ação", point.action))
                .position(by: .value("Ação", point.action))
            }
            .chartForegroundStyleScale(["Iniciaram": Color.green, "Pararam": Color.red])
            .chartXAxis { BrasiliaHourAxis.marks(for: points.map(\.date)) }
            .environment(\.timeZone, .brasilia)
            .frame(height: 240)
        }
        .padding()
        .background(platterColor)
        .cornerRadius(12)
    }
}

private struct ElectionLiveCumulativeChart: View {

    let hourly: [ElectionLiveHourlyCount]

    private struct Point: Identifiable {
        var id: Date { date }
        let date: Date
        let total: Int
    }

    private var points: [Point] {
        var runningTotal = 0
        return hourly.compactMap { item in
            guard let date = item.date else { return nil }
            runningTotal += item.newStarters
            return Point(date: date, total: runningTotal)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Total acumulado de pessoas")
                .font(.headline)
            Text("Pessoas distintas que já iniciaram no período")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart(points) { point in
                AreaMark(
                    x: .value("Hora", point.date, unit: .hour),
                    y: .value("Pessoas", point.total)
                )
                .foregroundStyle(.green.opacity(0.2))
                .interpolationMethod(.monotone)

                LineMark(
                    x: .value("Hora", point.date, unit: .hour),
                    y: .value("Pessoas", point.total)
                )
                .foregroundStyle(.green)
                .interpolationMethod(.monotone)
                .symbol(.circle)
            }
            .chartXAxis { BrasiliaHourAxis.marks(for: points.map(\.date)) }
            .environment(\.timeZone, .brasilia)
            .frame(height: 240)
        }
        .padding()
        .background(platterColor)
        .cornerRadius(12)
    }
}

// MARK: - Versions

private struct ElectionLiveVersionList: View {

    let versions: [ElectionLiveVersionCount]
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Por versão do app")
                .font(.headline)

            ForEach(versions) { version in
                HStack {
                    Text(version.appVersion.isEmpty ? "Desconhecida" : version.appVersion)
                        .font(.body.monospacedDigit())
                    Spacer()
                    Text(version.starters.formatted())
                        .font(.body.bold().monospacedDigit())
                    if total > 0 {
                        Text((Double(version.starters) / Double(total)).formatted(.percent.precision(.fractionLength(0))))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 44, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(platterColor)
        .cornerRadius(12)
    }
}

// MARK: - Caveats

private struct ElectionLiveCaveats: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Como ler estes números", systemImage: "info.circle")
                .font(.subheadline.bold())
            Group {
                Text("• Só entram inícios e paradas feitos pelo banner \"Acompanhar ao Vivo\". A tela de resultados (13.1) não envia eventos, então os números ficam abaixo do real.")
                Text("• Um início só é contado se a Atividade ao Vivo começou de fato. Quem tem Atividades ao Vivo desligadas ou teve erro não aparece.")
                Text("• Pessoas são contadas por instalação: iniciar e parar várias vezes conta uma vez só.")
                Text("• \"Acompanhando agora\" considera quem teve como último evento um início nas últimas 8h. Não enxerga atividades encerradas pelo sistema ou pela tela de resultados.")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(platterColor.opacity(0.5))
        .cornerRadius(12)
    }
}
