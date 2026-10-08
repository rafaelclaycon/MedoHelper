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
    /// The 10-minute series, when the period fits in it and the server answered. The
    /// charts fall back to hourly without it.
    let series: ElectionLiveSeriesResponse?
    let onRetry: () -> Void

    var body: some View {
        switch state {
        case .loading:
            SectionLoadingView(title: sectionTitle, icon: sectionIcon, color: sectionColor)
        case .loaded(let response):
            ElectionLiveContent(response: response, series: series)
        case .error(let message):
            SectionErrorView(title: sectionTitle, icon: sectionIcon, color: sectionColor, message: message, retryAction: onRetry)
        }
    }
}

// MARK: - Content

private struct ElectionLiveContent: View {

    let response: ElectionLiveAnalyticsResponse
    let series: ElectionLiveSeriesResponse?

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
            } else if let series, !series.buckets.isEmpty {
                LazyVGrid(columns: chartColumns, alignment: .leading, spacing: 20) {
                    ElectionLiveSeriesTotalsChart(series: series)
                    ElectionLiveSeriesActivityChart(series: series)
                }
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

// MARK: - Series charts

/// Points of the 10-minute series. Counts that describe the end of a bucket (totals,
/// who's watching) sit at its end; counts of what happened in it span the bucket.
private struct SeriesBucketPoint {
    let start: Date
    let end: Date
    let bucket: ElectionLiveSeriesBucket

    static func points(_ series: ElectionLiveSeriesResponse) -> [SeriesBucketPoint] {
        let length = TimeInterval(series.bucketMinutes * 60)
        return series.buckets.compactMap { bucket in
            guard let start = bucket.date else { return nil }
            return SeriesBucketPoint(start: start, end: start.addingTimeInterval(length), bucket: bucket)
        }
    }
}

/// Hovering shows the time and both counts of the nearest bucket.
private struct ElectionLiveSeriesTotalsChart: View {

    let series: ElectionLiveSeriesResponse

    /// End of the hovered bucket. Settable for previews.
    @State private var hoveredDate: Date?

    init(series: ElectionLiveSeriesResponse, hoveredDate: Date? = nil) {
        self.series = series
        self._hoveredDate = State(initialValue: hoveredDate)
    }

    private static let totalLabel = "Já iniciaram"
    private static let watchingLabel = "Acompanhando (estimativa)"

    private struct Point: Identifiable {
        let id: String
        let date: Date
        let line: String
        let count: Int
    }

    private var buckets: [SeriesBucketPoint] {
        SeriesBucketPoint.points(series)
    }

    private var points: [Point] {
        buckets.flatMap { point in
            [
                Point(id: point.bucket.start + "-total", date: point.end, line: Self.totalLabel, count: point.bucket.cumulativeStarters),
                Point(id: point.bucket.start + "-watching", date: point.end, line: Self.watchingLabel, count: point.bucket.watchingEstimate)
            ]
        }
    }

    private var hovered: SeriesBucketPoint? {
        guard let hoveredDate else { return nil }
        return buckets.min { abs($0.end.timeIntervalSince(hoveredDate)) < abs($1.end.timeIntervalSince(hoveredDate)) }
    }

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = .brasilia
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pessoas ao longo do tempo")
                .font(.headline)
            Text("A cada \(series.bucketMinutes) min, horário de Brasília")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart {
                ForEach(points) { point in
                    line(point)
                }
                if let hovered {
                    hoverMarks(hovered)
                }
            }
            .chartForegroundStyleScale([Self.totalLabel: Color.green, Self.watchingLabel: Color.orange])
            .chartXAxis { BrasiliaHourAxis.marks(for: points.map(\.date)) }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .onContinuousHover { phase in
                            switch phase {
                            case .active(let location):
                                guard let plotFrame = proxy.plotFrame else { return }
                                let x = location.x - geometry[plotFrame].origin.x
                                hoveredDate = proxy.value(atX: x, as: Date.self)
                            case .ended:
                                hoveredDate = nil
                            }
                        }
                }
            }
            .environment(\.timeZone, .brasilia)
            .frame(height: 240)
        }
        .padding()
        .background(platterColor)
        .cornerRadius(12)
    }

    private func line(_ point: Point) -> some ChartContent {
        LineMark(
            x: .value("Hora", point.date),
            y: .value("Pessoas", point.count)
        )
        .foregroundStyle(by: .value("Linha", point.line))
        .interpolationMethod(.monotone)
    }

    /// The card sits beside the rule, at the top, on the side with more room, so it never
    /// covers the hovered points.
    @ChartContentBuilder
    private func hoverMarks(_ point: SeriesBucketPoint) -> some ChartContent {
        let isOnRightHalf = (buckets.firstIndex { $0.end == point.end } ?? 0) > buckets.count / 2
        RuleMark(x: .value("Hora", point.end))
            .foregroundStyle(Color.secondary.opacity(0.6))
            .annotation(
                position: isOnRightHalf ? .leading : .trailing,
                alignment: .top,
                spacing: 8,
                overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))
            ) {
                hoverCard(point)
            }
        PointMark(x: .value("Hora", point.end), y: .value("Pessoas", point.bucket.cumulativeStarters))
            .foregroundStyle(Color.green)
        PointMark(x: .value("Hora", point.end), y: .value("Pessoas", point.bucket.watchingEstimate))
            .foregroundStyle(Color.orange)
    }

    private func hoverCard(_ point: SeriesBucketPoint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Self.timeFormatter.string(from: point.end))
                .font(.caption.bold().monospacedDigit())
            hoverRow(color: .green, label: Self.totalLabel, value: point.bucket.cumulativeStarters)
            hoverRow(color: .orange, label: Self.watchingLabel, value: point.bucket.watchingEstimate)
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private func hoverRow(color: Color, label: String, value: Int) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value.formatted())
                .font(.caption.bold().monospacedDigit())
        }
    }
}

/// Starts above zero and stops below it, per bucket.
private struct ElectionLiveSeriesActivityChart: View {

    let series: ElectionLiveSeriesResponse

    private static let startLabel = "Iniciaram"
    private static let stopLabel = "Pararam"

    private struct Point: Identifiable {
        let id: String
        let start: Date
        let end: Date
        let action: String
        let count: Int
    }

    private var points: [Point] {
        SeriesBucketPoint.points(series).flatMap { point in
            [
                Point(id: point.bucket.start + "-start", start: point.start, end: point.end, action: Self.startLabel, count: point.bucket.starters),
                Point(id: point.bucket.start + "-stop", start: point.start, end: point.end, action: Self.stopLabel, count: -point.bucket.stoppers)
            ]
        }
    }

    /// A bar from zero over the bucket's span: up for starts, down for stops.
    private func bar(_ point: Point) -> some ChartContent {
        let zero: Int = 0
        return RectangleMark(
            xStart: .value("Início", point.start),
            xEnd: .value("Fim", point.end),
            yStart: .value("Zero", zero),
            yEnd: .value("Pessoas", point.count)
        )
        .foregroundStyle(by: .value("Ação", point.action))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Inícios e paradas")
                .font(.headline)
            Text("Pessoas a cada \(series.bucketMinutes) min. Abaixo do zero, quem parou.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart {
                ForEach(points) { point in
                    bar(point)
                }
                RuleMark(y: .value("Zero", 0))
                    .foregroundStyle(Color.gray)
            }
            .chartForegroundStyleScale([Self.startLabel: Color.green, Self.stopLabel: Color.red])
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let count = value.as(Int.self) {
                            Text(abs(count).formatted())
                        }
                    }
                }
            }
            .chartXAxis { BrasiliaHourAxis.marks(for: points.map(\.start)) }
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
                Text("• Entram os inícios e as paradas feitos pelo banner \"Acompanhar ao Vivo\" e, a partir da versão seguinte à 13.2, pela tela de resultados. Nas versões 13.1 e 13.2, a tela de resultados não envia eventos, então o 1º turno (04/10) ficou abaixo do real.")
                Text("• Um início só é contado se a Atividade ao Vivo começou de fato. Quem tem Atividades ao Vivo desligadas ou teve erro não aparece.")
                Text("• Pessoas são contadas por instalação: iniciar e parar várias vezes conta uma vez só.")
                Text("• \"Acompanhando agora\" considera quem teve como último evento um início nas últimas 8h. Não enxerga atividades encerradas pelo sistema ou pelo push de fim da apuração: depois do resultado final, a estimativa fica acima do real. A linha \"Acompanhando\" dos gráficos usa a mesma regra a cada intervalo.")
                Text("• Os cartões contam do início do período até agora. Em \"04/10\" e \"25/10\", os gráficos vão das 17h às 3h do dia seguinte, no horário de Brasília.")
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
