//
//  EpisodeFeatureSections.swift
//  MedoHelper
//
//  Created by Claude on 19/10/26.
//

import SwiftUI
import Charts

private let platterColor = Color.gray.opacity(0.3)
private let cardColumns = [GridItem(.adaptive(minimum: 220), spacing: 12, alignment: .top)]
private let chartColumns = [GridItem(.adaptive(minimum: 380), spacing: 20, alignment: .top)]

/// Title row shared by the episode feature sections, like the election and games ones.
private struct FeatureSectionHeader: View {

    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title2)
            Text(title)
                .font(.title2.bold())
            Spacer()
            Text("Últimos 30 dias")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Episodes

private let episodesTitle = "Episódios"
private let episodesIcon = "play.circle"
private let episodesColor = Color.red

/// Who opened, played and bookmarked episodes, plus which episodes have a transcript.
struct EpisodesSection: View {

    let state: LoadingState<EpisodeAnalyticsResponse>
    let transcripts: LoadingState<[PodcastEpisode]>
    let onRetry: () -> Void

    var body: some View {
        switch state {
        case .loading:
            SectionLoadingView(title: episodesTitle, icon: episodesIcon, color: episodesColor)
        case .loaded(let response):
            EpisodesContent(response: response, transcripts: transcripts, onRetry: onRetry)
        case .error(let message):
            SectionErrorView(title: episodesTitle, icon: episodesIcon, color: episodesColor, message: message, retryAction: onRetry)
        }
    }
}

private struct EpisodesContent: View {

    let response: EpisodeAnalyticsResponse
    let transcripts: LoadingState<[PodcastEpisode]>
    let onRetry: () -> Void

    private var viewers: Int { response.totalViewers ?? response.totalUniqueUsers }

    private func share(of count: Int) -> String {
        let percent = viewers > 0 ? Double(count) / Double(viewers) * 100 : 0
        return String(format: "%.0f%% de quem abriu", percent)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureSectionHeader(title: episodesTitle, icon: episodesIcon, color: episodesColor)

            LazyVGrid(columns: cardColumns, alignment: .leading, spacing: 12) {
                EpisodeMiniStatCard(title: "Ouvintes Únicos", value: "\(response.totalUniqueUsers)", icon: "person.2.fill", color: episodesColor)
                EpisodeMiniStatCard(
                    title: "Reproduziram",
                    value: "\(response.usersWhoPlayed)",
                    subtitle: share(of: response.usersWhoPlayed),
                    icon: "play.circle.fill",
                    color: episodesColor
                )
                EpisodeMiniStatCard(
                    title: "Favoritaram",
                    value: "\(response.usersWhoBookmarked)",
                    subtitle: share(of: response.usersWhoBookmarked),
                    icon: "bookmark.fill",
                    color: episodesColor
                )
                EpisodeMiniStatCard(title: "Média Reproduções/Usuário", value: String(format: "%.2f", response.averagePlaysPerUser), icon: "arrow.triangle.2.circlepath", color: episodesColor)
                EpisodeMiniStatCard(title: "Média Favoritos/Usuário", value: String(format: "%.2f", response.averageBookmarksPerUser), icon: "bookmark.circle.fill", color: episodesColor)
            }

            LazyVGrid(columns: chartColumns, alignment: .leading, spacing: 20) {
                if !response.dailyUniqueUsers.isEmpty {
                    EpisodeDailyUsersChart(dailyUsers: response.dailyUniqueUsers)
                }
                TranscriptStatusList(state: transcripts, onRetry: onRetry)
            }
        }
    }
}

private struct TranscriptStatusList: View {

    let state: LoadingState<[PodcastEpisode]>
    let onRetry: () -> Void

    var body: some View {
        switch state {
        case .loading:
            SectionLoadingView(title: "Status de Transcrições", icon: "text.document", color: .teal)
        case .loaded(let episodes):
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "text.document")
                        .foregroundColor(.teal)
                        .font(.title2)
                    Text("Status de Transcrições")
                        .font(.headline)

                    Spacer()

                    let transcribed = episodes.filter(\.isTranscribed).count
                    Text("\(transcribed)/\(episodes.count)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(transcribed == episodes.count ? .green : .orange)
                }
                .padding(.horizontal)

                VStack(spacing: 6) {
                    ForEach(episodes) { episode in
                        TranscriptStatusRow(episode: episode)
                    }
                }
            }
            .padding()
            .background(platterColor)
            .cornerRadius(12)
        case .error(let message):
            SectionErrorView(title: "Status de Transcrições", icon: "text.document", color: .teal, message: message, retryAction: onRetry)
        }
    }
}

// MARK: - Share Clip

private let shareClipTitle = "Compartilhar Clipe"
private let shareClipIcon = "film.fill"
private let shareClipColor = Color.indigo

/// From the "Compartilhar Clipe" button in Now Playing to the shared video.
struct ShareClipSection: View {

    let state: LoadingState<ShareClipAnalyticsResponse>
    let onRetry: () -> Void

    var body: some View {
        switch state {
        case .loading:
            SectionLoadingView(title: shareClipTitle, icon: shareClipIcon, color: shareClipColor)
        case .loaded(let response):
            VStack(alignment: .leading, spacing: 16) {
                FeatureSectionHeader(title: shareClipTitle, icon: shareClipIcon, color: shareClipColor)

                LazyVGrid(columns: cardColumns, alignment: .leading, spacing: 12) {
                    EpisodeMiniStatCard(title: "Toques em \"Compartilhar Clipe\"", value: "\(response.tapCount)", icon: "hand.tap.fill", color: shareClipColor)
                    EpisodeMiniStatCard(
                        title: "Compartilhados",
                        value: "\(response.sharedCount)",
                        subtitle: String(format: "%.0f%% de conversão", response.conversionRate * 100),
                        icon: "square.and.arrow.up.fill",
                        color: shareClipColor
                    )
                    EpisodeMiniStatCard(title: "Falhas na Geração", value: "\(response.generationFailedCount)", icon: "exclamationmark.triangle.fill", color: shareClipColor)
                    EpisodeMiniStatCard(title: "Com Transcrição", value: "\(response.sharedWithTranscriptCount)", icon: "text.quote", color: shareClipColor)
                    EpisodeMiniStatCard(title: "Sem Transcrição", value: "\(response.sharedWithoutTranscriptCount)", icon: "text.slash", color: shareClipColor)
                    EpisodeMiniStatCard(title: "Pedido de Apoio Exibido", value: "\(response.supportPromptShownCount)", icon: "heart.fill", color: shareClipColor)
                    EpisodeMiniStatCard(title: "\"O Que Há de Novo\" Dispensado", value: "\(response.whatsNewDismissedCount)", icon: "sparkles", color: shareClipColor)
                }

                if !response.dailySharesLast30Days.isEmpty {
                    ShareClipDailyChart(dailyShares: response.dailySharesLast30Days)
                }
            }
        case .error(let message):
            SectionErrorView(title: shareClipTitle, icon: shareClipIcon, color: shareClipColor, message: message, retryAction: onRetry)
        }
    }
}

// MARK: - Chapters

private let chaptersTitle = "Capítulos"
private let chaptersIcon = "list.bullet.rectangle.fill"
private let chaptersColor = Color.purple

/// Taps on episode chapters, how the chapter lists load, and the most tapped chapters.
struct ChaptersSection: View {

    let state: LoadingState<ChaptersUsageAnalyticsResponse>
    let onRetry: () -> Void

    var body: some View {
        switch state {
        case .loading:
            SectionLoadingView(title: chaptersTitle, icon: chaptersIcon, color: chaptersColor)
        case .loaded(let response):
            ChaptersContent(response: response)
        case .error(let message):
            SectionErrorView(title: chaptersTitle, icon: chaptersIcon, color: chaptersColor, message: message, retryAction: onRetry)
        }
    }
}

private struct ChaptersContent: View {

    let response: ChaptersUsageAnalyticsResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureSectionHeader(title: chaptersTitle, icon: chaptersIcon, color: chaptersColor)

            LazyVGrid(columns: cardColumns, alignment: .leading, spacing: 12) {
                EpisodeMiniStatCard(title: "Toques em Capítulos", value: "\(response.tapCount)", icon: "hand.tap.fill", color: chaptersColor)
                EpisodeMiniStatCard(title: "Detalhe do Episódio", value: "\(response.tapCountEpisodeDetail)", icon: "doc.text.fill", color: chaptersColor)
                EpisodeMiniStatCard(title: "Tocando Agora", value: "\(response.tapCountNowPlaying)", icon: "play.circle.fill", color: chaptersColor)
                EpisodeMiniStatCard(title: "Capítulo Anterior", value: "\(response.previousCount)", icon: "backward.end.fill", color: chaptersColor)
                EpisodeMiniStatCard(title: "Próximo Capítulo", value: "\(response.nextCount)", icon: "forward.end.fill", color: chaptersColor)
                EpisodeMiniStatCard(
                    title: "Carregados com Sucesso",
                    value: "\(response.loadedCount)",
                    subtitle: String(format: "%.0f%% de sucesso", response.loadSuccessRate * 100),
                    icon: "checkmark.circle.fill",
                    color: chaptersColor
                )
                EpisodeMiniStatCard(title: "Falhas ao Carregar", value: "\(response.loadFailedCount)", icon: "exclamationmark.triangle.fill", color: chaptersColor)
                EpisodeMiniStatCard(title: "Lista Ocultada", value: "\(response.hiddenCount)", icon: "eye.slash.fill", color: chaptersColor)
                EpisodeMiniStatCard(title: "Problema Reportado", value: "\(response.issueReportedCount)", icon: "flag.fill", color: chaptersColor)
            }

            LazyVGrid(columns: chartColumns, alignment: .leading, spacing: 20) {
                if !response.dailyChapterTapsLast30Days.isEmpty {
                    ChaptersDailyChart(dailyTaps: response.dailyChapterTapsLast30Days)
                }
                if !response.topChapters.isEmpty {
                    TopChaptersList(chapters: response.topChapters)
                }
            }
        }
    }
}

private struct TopChaptersList: View {

    let chapters: [TopChapter]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Capítulos Mais Tocados")
                .font(.headline)

            ForEach(chapters) { chapter in
                HStack {
                    Text(chapter.title)
                        .lineLimit(1)
                    Spacer()
                    Text("\(chapter.tapCount)")
                        .font(.body.bold().monospacedDigit())
                        .foregroundStyle(chaptersColor)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(platterColor)
        .cornerRadius(12)
    }
}

// MARK: - Episode Daily Users Chart

private struct EpisodeDailyUsersChart: View {
    let dailyUsers: [EpisodeDailyUserCount]
    @State private var selectedDate: Date?
    
    var selectedDataPoint: EpisodeDailyUserCount? {
        guard let selectedDate = selectedDate else { return nil }
        return dailyUsers.first { dataPoint in
            guard let dateValue = dataPoint.dateValue else { return false }
            return Calendar.current.isDate(dateValue, inSameDayAs: selectedDate)
        }
    }
    
    var sundayDates: [Date] {
        dailyUsers.compactMap { dataPoint -> Date? in
            guard let date = dataPoint.dateValue else { return nil }
            return Calendar.current.component(.weekday, from: date) == 1 ? date : nil
        }
    }

    var fridayDates: [Date] {
        dailyUsers.compactMap { dataPoint -> Date? in
            guard let date = dataPoint.dateValue else { return nil }
            return Calendar.current.component(.weekday, from: date) == 6 ? date : nil
        }
    }

    var medianValue: Int {
        let sortedCounts = dailyUsers.map { $0.activeUsers }.filter { $0 > 0 }.sorted()
        let count = sortedCounts.count
        if count == 0 {
            return 0
        } else if count % 2 == 0 {
            return (sortedCounts[count / 2 - 1] + sortedCounts[count / 2]) / 2
        } else {
            return sortedCounts[count / 2]
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.red)
                    .font(.title2)
                Text("Ouvintes Únicos - Últimos 30 Dias")
                    .font(.headline)
                Spacer()
                
                if let selected = selectedDataPoint {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formattedDate(selected.date))
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("\(selected.activeUsers) usuários")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            
            Chart {
                ForEach(dailyUsers) { dataPoint in
                    LineMark(
                        x: .value("Data", dataPoint.dateValue ?? Date(), unit: .day),
                        y: .value("Usuários", dataPoint.activeUsers)
                    )
                    .foregroundStyle(.red)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Data", dataPoint.dateValue ?? Date(), unit: .day),
                        y: .value("Usuários", dataPoint.activeUsers)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red.opacity(0.3), .red.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    if let selectedDate = selectedDate,
                       let dateValue = dataPoint.dateValue,
                       Calendar.current.isDate(dateValue, inSameDayAs: selectedDate) {
                        PointMark(
                            x: .value("Data", dateValue, unit: .day),
                            y: .value("Usuários", dataPoint.activeUsers)
                        )
                        .foregroundStyle(.red)
                        .symbolSize(100)
                    }
                }
                
                if let selectedDate = selectedDate {
                    RuleMark(x: .value("Data", selectedDate, unit: .day))
                        .foregroundStyle(.red.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                }
                
                RuleMark(y: .value("Mediana", medianValue))
                    .foregroundStyle(.orange.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Mediana: \(medianValue)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                            .padding(4)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                    }

                ForEach(sundayDates, id: \.self) { sunday in
                    RuleMark(x: .value("Domingo", sunday, unit: .day))
                        .foregroundStyle(.purple.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .annotation(position: .top, alignment: .center, spacing: 0) {
                            Text("D")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(.purple)
                        }
                }

                ForEach(fridayDates, id: \.self) { friday in
                    RuleMark(x: .value("Sexta", friday, unit: .day))
                        .foregroundStyle(.green.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .annotation(position: .top, alignment: .center, spacing: 0) {
                            Text("S")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(.green)
                        }
                }
            }
            .chartXSelection(value: $selectedDate)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day(), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(platterColor)
        .cornerRadius(12)
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        return displayFormatter.string(from: date)
    }
}

// MARK: - Share Clip Daily Chart

private struct ShareClipDailyChart: View {
    let dailyShares: [ShareClipDailyCount]
    @State private var selectedDate: Date?

    var selectedDataPoint: ShareClipDailyCount? {
        guard let selectedDate = selectedDate else { return nil }
        return dailyShares.first { dataPoint in
            guard let dateValue = dataPoint.dateValue else { return false }
            return Calendar.current.isDate(dateValue, inSameDayAs: selectedDate)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.indigo)
                    .font(.title2)
                Text("Compartilhamentos - Últimos 30 Dias")
                    .font(.headline)
                Spacer()

                if let selected = selectedDataPoint {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formattedDate(selected.date))
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("\(selected.activeUsers) compartilhamentos")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)

            Chart {
                ForEach(dailyShares) { dataPoint in
                    LineMark(
                        x: .value("Data", dataPoint.dateValue ?? Date(), unit: .day),
                        y: .value("Compartilhamentos", dataPoint.activeUsers)
                    )
                    .foregroundStyle(.indigo)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Data", dataPoint.dateValue ?? Date(), unit: .day),
                        y: .value("Compartilhamentos", dataPoint.activeUsers)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.indigo.opacity(0.3), .indigo.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    if let selectedDate = selectedDate,
                       let dateValue = dataPoint.dateValue,
                       Calendar.current.isDate(dateValue, inSameDayAs: selectedDate) {
                        PointMark(
                            x: .value("Data", dateValue, unit: .day),
                            y: .value("Compartilhamentos", dataPoint.activeUsers)
                        )
                        .foregroundStyle(.indigo)
                        .symbolSize(100)
                    }
                }

                if let selectedDate = selectedDate {
                    RuleMark(x: .value("Data", selectedDate, unit: .day))
                        .foregroundStyle(.indigo.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                }
            }
            .chartXSelection(value: $selectedDate)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day(), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(platterColor)
        .cornerRadius(12)
    }

    private func formattedDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        return displayFormatter.string(from: date)
    }
}

// MARK: - Chapters Daily Chart

private struct ChaptersDailyChart: View {
    let dailyTaps: [ChaptersDailyCount]
    @State private var selectedDate: Date?

    var selectedDataPoint: ChaptersDailyCount? {
        guard let selectedDate = selectedDate else { return nil }
        return dailyTaps.first { dataPoint in
            guard let dateValue = dataPoint.dateValue else { return false }
            return Calendar.current.isDate(dateValue, inSameDayAs: selectedDate)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.purple)
                    .font(.title2)
                Text("Toques em Capítulos - Últimos 30 Dias")
                    .font(.headline)
                Spacer()

                if let selected = selectedDataPoint {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formattedDate(selected.date))
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("\(selected.tapCount) toques")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)

            Chart {
                ForEach(dailyTaps) { dataPoint in
                    LineMark(
                        x: .value("Data", dataPoint.dateValue ?? Date(), unit: .day),
                        y: .value("Toques", dataPoint.tapCount)
                    )
                    .foregroundStyle(.purple)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Data", dataPoint.dateValue ?? Date(), unit: .day),
                        y: .value("Toques", dataPoint.tapCount)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple.opacity(0.3), .purple.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    if let selectedDate = selectedDate,
                       let dateValue = dataPoint.dateValue,
                       Calendar.current.isDate(dateValue, inSameDayAs: selectedDate) {
                        PointMark(
                            x: .value("Data", dateValue, unit: .day),
                            y: .value("Toques", dataPoint.tapCount)
                        )
                        .foregroundStyle(.purple)
                        .symbolSize(100)
                    }
                }

                if let selectedDate = selectedDate {
                    RuleMark(x: .value("Data", selectedDate, unit: .day))
                        .foregroundStyle(.purple.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                }
            }
            .chartXSelection(value: $selectedDate)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day(), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(platterColor)
        .cornerRadius(12)
    }

    private func formattedDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dateString) else {
            return dateString
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        return displayFormatter.string(from: date)
    }
}

// MARK: - Transcript Status Row

private struct TranscriptStatusRow: View {
    let episode: PodcastEpisode

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: episode.isTranscribed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(episode.isTranscribed ? .green : .red)
                .font(.system(size: 16))

            VStack(alignment: .leading, spacing: 2) {
                Text(episode.title)
                    .font(.subheadline)
                    .lineLimit(1)
                if let pubDate = episode.pubDate {
                    Text(pubDate, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(episode.id)
                .font(.caption2)
                .foregroundColor(.secondary)
                .monospaced()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}
