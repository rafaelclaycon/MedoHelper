//
//  GamesSection.swift
//  MedoHelper
//
//  Created by Claude on 18/10/26.
//

import SwiftUI
import Charts

private let platterColor = Color.gray.opacity(0.3)
private let sectionTitle = "Jogos"
private let sectionIcon = "gamecontroller.fill"
private let sectionColor = Color.indigo

/// Usage of the games, from the events the game screens send.
struct GamesSection: View {

    let state: LoadingState<GamesAnalyticsResponse>
    @Binding var window: FeatureAnalyticsView.GamesWindow
    let onRetry: () -> Void

    var body: some View {
        switch state {
        case .loading:
            SectionLoadingView(title: sectionTitle, icon: sectionIcon, color: sectionColor)
        case .loaded(let response):
            GamesContent(response: response, window: $window)
        case .error(let message):
            SectionErrorView(title: sectionTitle, icon: sectionIcon, color: sectionColor, message: message, retryAction: onRetry)
        }
    }
}

// MARK: - Content

private struct GamesContent: View {

    let response: GamesAnalyticsResponse
    @Binding var window: FeatureAnalyticsView.GamesWindow

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
                Picker("Janela dos jogos", selection: $window) {
                    ForEach(FeatureAnalyticsView.GamesWindow.allCases) { window in
                        Text(window.label).tag(window)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
            }

            LazyVGrid(columns: cardColumns, alignment: .leading, spacing: 12) {
                EpisodeMiniStatCard(
                    title: "Pessoas que jogaram",
                    value: response.players.formatted(),
                    subtitle: "\(percent(response.playerPercentage)) de \(response.activeUsersWithGames.formatted()) na 13.6+",
                    icon: "person.2.fill",
                    color: sectionColor
                )
                EpisodeMiniStatCard(
                    title: "Voltaram a jogar",
                    value: response.returningPlayers.formatted(),
                    subtitle: "Jogaram em 2 dias ou mais",
                    icon: "arrow.uturn.backward.circle.fill",
                    color: .teal
                )
                EpisodeMiniStatCard(
                    title: "Partidas iniciadas",
                    value: response.starts.formatted(),
                    subtitle: "\(response.finishes.formatted()) terminadas (\(percent(response.completionPercentage)))",
                    icon: "play.circle.fill",
                    color: .green
                )
                EpisodeMiniStatCard(
                    title: "Abandonos",
                    value: response.abandons.formatted(),
                    subtitle: "Saíram antes do fim",
                    icon: "door.left.hand.open",
                    color: .red
                )
                EpisodeMiniStatCard(
                    title: "Compartilhamentos",
                    value: response.shares.formatted(),
                    subtitle: "De resultados de partidas",
                    icon: "square.and.arrow.up.fill",
                    color: .orange
                )
                EpisodeMiniStatCard(
                    title: "Pedido de apoio aberto",
                    value: response.supportSheetShownCount.formatted(),
                    subtitle: "Pelo cartão dos jogos",
                    icon: "heart.fill",
                    color: .pink
                )
            }

            if response.starts == 0 {
                ContentUnavailableView {
                    Label("Ninguém Jogou", systemImage: sectionIcon)
                } description: {
                    Text("Nenhuma partida começou nos últimos \(response.days) dias.")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(platterColor)
                .cornerRadius(12)
            } else {
                GamesDailyChart(daily: response.daily)

                LazyVGrid(columns: chartColumns, alignment: .leading, spacing: 20) {
                    ForEach(response.games) { game in
                        GameCard(game: game)
                    }
                }

                LazyVGrid(columns: chartColumns, alignment: .leading, spacing: 20) {
                    GamesSharesList(response: response)
                    GamesHealthList(response: response)
                }
            }

            GamesCaveats()
        }
    }
}

private func percent(_ value: Double) -> String {
    (value / 100).formatted(.percent.precision(.fractionLength(0...1)))
}

// MARK: - Daily Chart

private struct GamesDailyChart: View {

    let daily: [GamesAnalyticsDay]

    private struct Point: Identifiable {
        let id: String
        let date: Date
        let series: String
        let count: Int
    }

    private var points: [Point] {
        daily.flatMap { item -> [Point] in
            guard let date = item.day else { return [] }
            return [
                Point(id: item.date + "-players", date: date, series: "Jogaram", count: item.players),
                Point(id: item.date + "-new", date: date, series: "Primeira vez no período", count: item.newPlayers)
            ]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pessoas por dia")
                .font(.headline)
            Text("Dias em UTC")
                .font(.caption)
                .foregroundStyle(.secondary)

            Chart(points) { point in
                LineMark(
                    x: .value("Dia", point.date, unit: .day),
                    y: .value("Pessoas", point.count)
                )
                .foregroundStyle(by: .value("Série", point.series))

                PointMark(
                    x: .value("Dia", point.date, unit: .day),
                    y: .value("Pessoas", point.count)
                )
                .foregroundStyle(by: .value("Série", point.series))
                .symbolSize(20)
            }
            .chartForegroundStyleScale(["Jogaram": sectionColor, "Primeira vez no período": Color.teal])
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 8)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.day().month(.twoDigits))
                }
            }
            .environment(\.timeZone, .utc)
            .frame(height: 240)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(platterColor)
        .cornerRadius(12)
    }
}

// MARK: - Per Game

private struct GameCard: View {

    let game: GamesAnalyticsGame

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(game.displayName)
                .font(.headline)

            VStack(spacing: 6) {
                row("Pessoas", game.players.formatted())
                row("Partidas", game.starts.formatted())
                row("Terminadas", "\(game.finishes.formatted()) (\(percent(game.completionPercentage)))")
                row("Abandonos", game.abandons.formatted())
                if let averageScore = game.averageScore {
                    row(
                        game.scoresPoints ? "Pontuação média" : "Acertos médios",
                        averageScore.formatted(.number.precision(.fractionLength(0...1)))
                    )
                }
                if game.scoresPoints, let averageHits = game.averageHits {
                    row("Acertos médios", averageHits.formatted(.number.precision(.fractionLength(0...1))))
                }
                if let seconds = game.averageSecondsPerRound {
                    row("Tempo médio por rodada", "\(seconds.formatted(.number.precision(.fractionLength(1)))) s")
                }
                row("Novos recordes", game.newRecords.formatted())
                row("Compartilhamentos", game.shares.formatted())
            }

            if !game.hitsDistribution.isEmpty {
                Text("Partidas terminadas por acertos")
                    .font(.subheadline.bold())
                Chart(game.hitsDistribution) { item in
                    BarMark(
                        x: .value("Acertos", String(item.hits)),
                        y: .value("Partidas", item.finishes)
                    )
                    .foregroundStyle(sectionColor.gradient)
                }
                .chartXScale(domain: (0...10).map(String.init))
                .frame(height: 140)
            }

            if !game.abandonsByRound.isEmpty {
                Text("Abandonos por rodada")
                    .font(.subheadline.bold())
                Chart(game.abandonsByRound) { item in
                    BarMark(
                        x: .value("Rodada", String(item.round)),
                        y: .value("Abandonos", item.abandons - item.answered)
                    )
                    .foregroundStyle(by: .value("Momento", "Antes de responder"))
                    BarMark(
                        x: .value("Rodada", String(item.round)),
                        y: .value("Abandonos", item.answered)
                    )
                    .foregroundStyle(by: .value("Momento", "Depois de responder"))
                }
                .chartForegroundStyleScale(["Antes de responder": Color.red, "Depois de responder": Color.orange])
                .chartXScale(domain: (1...10).map(String.init))
                .frame(height: 140)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(platterColor)
        .cornerRadius(12)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.body.bold().monospacedDigit())
        }
    }
}

// MARK: - Lists

private struct GamesSharesList: View {

    let response: GamesAnalyticsResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Compartilhamentos")
                .font(.headline)

            if response.shares == 0 {
                Text("Ninguém compartilhou um resultado no período.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(response.sharesByFormat) { format in
                    countRow(Self.formatName(format.name), format.count)
                }
                Divider()
                ForEach(response.sharesByDestination) { destination in
                    countRow(Self.destinationName(destination.name), destination.count)
                        .help(destination.name)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(platterColor)
        .cornerRadius(12)
    }

    private func countRow(_ title: String, _ count: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(count.formatted())
                .font(.body.bold().monospacedDigit())
            Text((Double(count) / Double(max(response.shares, 1))).formatted(.percent.precision(.fractionLength(0))))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)
        }
    }

    static func formatName(_ format: String) -> String {
        switch format {
        case "square": return "Formato quadrado"
        case "stories": return "Formato stories"
        default: return format
        }
    }

    private static let destinationNames: [String: String] = [
        "com.burbn.instagram.shareextension": "Instagram",
        "net.whatsapp.WhatsApp.ShareExtension": "WhatsApp",
        "com.apple.UIKit.activity.SaveToCameraRoll": "Salvar imagem",
        "com.apple.UIKit.activity.Message": "Mensagens",
        "com.apple.UIKit.activity.CopyToPasteboard": "Copiar",
        "com.apple.UIKit.activity.AirDrop": "AirDrop",
        "com.apple.UIKit.activity.Mail": "Mail",
        "com.atebits.Tweetie2.ShareExtension": "X",
        "ph.telegra.Telegraph.Share": "Telegram",
        "com.facebook.Facebook.ShareExtension": "Facebook",
        "unknown": "Desconhecido"
    ]

    static func destinationName(_ activityType: String) -> String {
        destinationNames[activityType] ?? activityType
    }
}

private struct GamesHealthList: View {

    let response: GamesAnalyticsResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Outros eventos")
                .font(.headline)

            HStack {
                Label("Música desligada", systemImage: "speaker.slash.fill")
                Spacer()
                Text(response.musicMutedCount.formatted())
                    .font(.body.bold().monospacedDigit())
            }
            HStack {
                Label("Música religada", systemImage: "speaker.wave.2.fill")
                Spacer()
                Text(response.musicUnmutedCount.formatted())
                    .font(.body.bold().monospacedDigit())
            }

            Divider()

            Text("Fotos de autor que não carregaram")
                .font(.subheadline.bold())
            if response.brokenAuthorPhotos.isEmpty {
                Text("Nenhuma no período.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(response.brokenAuthorPhotos) { author in
                    HStack {
                        Text(author.name)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Text(author.count.formatted())
                            .font(.body.bold().monospacedDigit())
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

private struct GamesCaveats: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Como ler estes números", systemImage: "info.circle")
                .font(.subheadline.bold())
            Group {
                Text("• Pessoas são contadas por instalação. A porcentagem compara quem jogou com quem abriu o app numa versão com jogos (13.6 ou mais nova) no período.")
                Text("• Terminadas e abandonos não somam as partidas iniciadas: quem fecha o app no meio do jogo não envia nenhum dos dois.")
                Text("• Em \"De quem é essa fuça?\" a pontuação vai de 0 a cerca de 10.000 (mais rápido, mais pontos). Em \"Eu já ouvi essa voz antes…\" ela é o número de acertos.")
                Text("• \"Voltaram a jogar\" e \"Primeira vez no período\" olham só para a janela escolhida, com dias em UTC (21h no horário de Brasília).")
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
