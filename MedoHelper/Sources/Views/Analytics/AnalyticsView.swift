//
//  AnalyticsView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 23/05/23.
//

import SwiftUI
import Charts
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

private let platterColor = Color.gray.opacity(0.3)

struct AnalyticsView: View {
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    // Individual loading states for each section
    @State private var activeUsers: LoadingState<Int> = .loading
    @State private var dailyUserCounts: LoadingState<[DailyUserCount]> = .loading
    @State private var deviceAnalytics: LoadingState<DeviceAnalyticsResponse> = .loading
    @State private var navigationAnalytics: LoadingState<NavigationAnalyticsResponse> = .loading
    
    // Release Rollout states
    @State private var rolloutSelectedDate: Date = Date()
    @State private var hourlyData: LoadingState<HourlyVersionResponse> = .loading
    @State private var dailyAdoption: LoadingState<[DailyVersionData]> = .loading
    @State private var distribution: LoadingState<VersionDistributionResponse> = .loading
    
    // Episode states
    @State private var episodeAnalytics: LoadingState<EpisodeAnalyticsResponse> = .loading
    @State private var transcriptStatuses: LoadingState<[PodcastEpisode]> = .loading
    
    @State private var lastUpdated: Date?
    @State private var selectedTimeSpan: AnalyticsTimeSpan = .today
    
    private let repository: AnalyticsRepositoryProtocol
    private let timer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()

    init(repository: AnalyticsRepositoryProtocol = AnalyticsRepository()) {
        self.repository = repository
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time span picker
                Picker("Período", selection: $selectedTimeSpan) {
                    ForEach(AnalyticsTimeSpan.allCases, id: \.self) { span in
                        Text(span.rawValue).tag(span)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: selectedTimeSpan) { _, _ in
                    fetchActiveUsers()
                }
                
                // Header with last updated time
                if let lastUpdated = lastUpdated {
                    HStack {
                        Spacer()
                        Text("Última atualização: \(formattedTime(lastUpdated))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                
                // Adaptive layout: VStack on iPhone, HStack on iPad/Mac
                let layout = horizontalSizeClass == .compact
                    ? AnyLayout(VStackLayout(spacing: 20))
                    : AnyLayout(HStackLayout(alignment: .top, spacing: 20))
                
                layout {
                    // Regular Analytics Column (Left)
                    VStack(alignment: .leading, spacing: 20) {
                        activeUsersSection
                        dailyUserCountsSection
                        deviceAnalyticsSection
                        navigationAnalyticsSection
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Release Rollout Column (Center)
                    VStack(spacing: 20) {
                        rolloutHeaderSection
                        distributionCardsSection
                        hourlyChartSection
                        versionPieChartSection
                        dailyTrendSection
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Episodes Column (Right)
                    VStack(spacing: 20) {
                        episodeHeaderSection
                        episodeAnalyticsSection
                        transcriptStatusSection
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical)
            .padding(.horizontal)
        }
        .navigationTitle("Estatísticas do App")
        .onAppear {
            fetchAllSections()
        }
        .onReceive(timer) { _ in
            fetchAllSections()
        }
    }
    
    // MARK: - Section Views
    
    @ViewBuilder
    private var activeUsersSection: some View {
        switch activeUsers {
        case .loading:
            StatCardLoading(title: selectedTimeSpan.displayTitle, icon: "person.2.fill", color: .blue)
        case .loaded(let count):
            StatCard(title: selectedTimeSpan.displayTitle, value: "\(count)", icon: "person.2.fill", color: .blue)
        case .error(let message):
            StatCardError(title: selectedTimeSpan.displayTitle, icon: "person.2.fill", color: .blue, message: message) {
                fetchActiveUsers()
            }
        }
    }
    
    @ViewBuilder
    private var dailyUserCountsSection: some View {
        switch dailyUserCounts {
        case .loading:
            SectionLoadingView(title: "Usuários - Últimos 30 Dias", icon: "chart.line.uptrend.xyaxis", color: .blue)
        case .loaded(let counts):
            if !counts.isEmpty {
                DailyUserCountChart(dailyUserCounts: counts)
            }
        case .error(let message):
            SectionErrorView(
                title: "Usuários - Últimos 30 Dias",
                icon: "chart.line.uptrend.xyaxis",
                color: .blue,
                message: message
            ) {
                fetchDailyUserCounts()
            }
        }
    }
    
    @ViewBuilder
    private var deviceAnalyticsSection: some View {
        switch deviceAnalytics {
        case .loading:
            SectionLoadingView(title: "Dispositivos e Sistema", icon: "iphone", color: .blue)
        case .loaded(let analytics):
            DeviceAnalyticsSection(analytics: analytics, repository: repository)
        case .error(let message):
            SectionErrorView(
                title: "Dispositivos e Sistema",
                icon: "iphone",
                color: .blue,
                message: message
            ) {
                fetchDeviceAnalytics()
            }
        }
    }
    
    @ViewBuilder
    private var navigationAnalyticsSection: some View {
        switch navigationAnalytics {
        case .loading:
            SectionLoadingView(title: "Navegação no App", icon: "map", color: .indigo)
        case .loaded(let analytics):
            NavigationAnalyticsSection(analytics: analytics)
        case .error(let message):
            SectionErrorView(
                title: "Navegação no App",
                icon: "map",
                color: .indigo,
                message: message
            ) {
                fetchNavigationAnalytics()
            }
        }
    }
    
    // MARK: - Release Rollout Section Views
    
    private var rolloutHeaderSection: some View {
        HStack {
            HStack {
                Image(systemName: "arrow.up.circle")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("Release Rollout")
                    .font(.headline)
            }
            
            Spacer()
            
            DatePicker(
                "Data",
                selection: $rolloutSelectedDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .onChange(of: rolloutSelectedDate) { _, _ in
                fetchHourlyData()
            }
            
            Button(action: fetchRolloutData) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var distributionCardsSection: some View {
        switch distribution {
        case .loading:
            VStack(spacing: 16) {
                StatCardLoading(title: "Versão Mais Recente", icon: "arrow.up.circle.fill", color: .green)
                StatCardLoading(title: "Total de Usuários Hoje", icon: "person.2.fill", color: .blue)
            }
        case .loaded(let response):
            let latestVersion = response.versions.first
            VStack(spacing: 16) {
                if let latest = latestVersion {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                            Text("Versão \(latest.appVersion)")
                                .font(.headline)
                        }
                        
                        HStack(spacing: 20) {
                            VStack(alignment: .leading) {
                                Text("\(latest.uniqueUsers)")
                                    .font(.system(size: 32, weight: .bold))
                                Text("usuários")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let pct = latest.percentage {
                                VStack(alignment: .leading) {
                                    Text(String(format: "%.1f%%", pct))
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.green)
                                    Text("do total")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(platterColor)
                    .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        Text("Total Hoje")
                            .font(.headline)
                    }
                    
                    Text("\(response.totalUsers)")
                        .font(.system(size: 32, weight: .bold))
                    Text("usuários ativos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(platterColor)
                .cornerRadius(12)
            }
            .padding(.horizontal)
        case .error(let message):
            VStack(spacing: 16) {
                StatCardError(title: "Versão Mais Recente", icon: "arrow.up.circle.fill", color: .green, message: message) {
                    fetchDistribution()
                }
                StatCardError(title: "Total de Usuários Hoje", icon: "person.2.fill", color: .blue, message: message) {
                    fetchDistribution()
                }
            }
        }
    }
    
    @ViewBuilder
    private var hourlyChartSection: some View {
        switch hourlyData {
        case .loading:
            SectionLoadingView(title: "Adoção por Hora", icon: "clock.fill", color: .green)
        case .loaded(let response):
            HourlyAdoptionChart(response: response)
        case .error(let message):
            SectionErrorView(
                title: "Adoção por Hora",
                icon: "clock.fill",
                color: .green,
                message: message
            ) {
                fetchHourlyData()
            }
        }
    }
    
    @ViewBuilder
    private var versionPieChartSection: some View {
        switch distribution {
        case .loading:
            SectionLoadingView(title: "Distribuição de Versões", icon: "chart.pie.fill", color: .purple)
        case .loaded(let response):
            VersionPieChart(versions: response.versions, totalUsers: response.totalUsers)
        case .error(let message):
            SectionErrorView(
                title: "Distribuição de Versões",
                icon: "chart.pie.fill",
                color: .purple,
                message: message
            ) {
                fetchDistribution()
            }
        }
    }
    
    @ViewBuilder
    private var dailyTrendSection: some View {
        switch dailyAdoption {
        case .loading:
            SectionLoadingView(title: "Tendência - 7 Dias", icon: "chart.line.uptrend.xyaxis", color: .blue)
        case .loaded(let data):
            DailyVersionTrendChart(dailyData: data)
        case .error(let message):
            SectionErrorView(
                title: "Tendência - 7 Dias",
                icon: "chart.line.uptrend.xyaxis",
                color: .blue,
                message: message
            ) {
                fetchDailyAdoption()
            }
        }
    }
    
    // MARK: - Episode Section Views
    
    private var episodeHeaderSection: some View {
        HStack {
            HStack {
                Image(systemName: "play.circle")
                    .foregroundColor(.red)
                    .font(.title2)
                Text("Episódios")
                    .font(.headline)
            }
            
            Spacer()
            
            Button {
                fetchEpisodeAnalytics()
                fetchTranscriptStatuses()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var episodeAnalyticsSection: some View {
        switch episodeAnalytics {
        case .loading:
            VStack(spacing: 12) {
                StatCardLoading(title: "Total de Usuários Únicos", icon: "person.2.fill", color: .red)
                SectionLoadingView(title: "Usuários Únicos - Últimos 30 Dias", icon: "chart.line.uptrend.xyaxis", color: .red)
                StatCardLoading(title: "Reproduziram", icon: "play.circle.fill", color: .red)
                StatCardLoading(title: "Favoritaram", icon: "bookmark.fill", color: .red)
            }
        case .loaded(let response):
            let playedPct = response.totalUniqueUsers > 0
                ? Double(response.usersWhoPlayed) / Double(response.totalUniqueUsers) * 100
                : 0
            let bookmarkedPct = response.totalUniqueUsers > 0
                ? Double(response.usersWhoBookmarked) / Double(response.totalUniqueUsers) * 100
                : 0
            
            VStack(spacing: 12) {
                StatCard(title: "Total de Usuários Únicos", value: "\(response.totalUniqueUsers)", icon: "person.2.fill", color: .red)
                
                if !response.dailyUniqueUsers.isEmpty {
                    EpisodeDailyUsersChart(dailyUsers: response.dailyUniqueUsers)
                }
                
                HStack(spacing: 12) {
                    EpisodeMiniStatCard(
                        title: "Reproduziram",
                        value: "\(response.usersWhoPlayed)",
                        subtitle: String(format: "%.0f%% do total", playedPct),
                        icon: "play.circle.fill",
                        color: .red
                    )
                    EpisodeMiniStatCard(
                        title: "Favoritaram",
                        value: "\(response.usersWhoBookmarked)",
                        subtitle: String(format: "%.0f%% do total", bookmarkedPct),
                        icon: "bookmark.fill",
                        color: .red
                    )
                }
                .padding(.horizontal)
                
                HStack(spacing: 12) {
                    EpisodeMiniStatCard(title: "Média Reproduções/Usuário", value: String(format: "%.2f", response.averagePlaysPerUser), icon: "arrow.triangle.2.circlepath", color: .red)
                    EpisodeMiniStatCard(title: "Média Favoritos/Usuário", value: String(format: "%.2f", response.averageBookmarksPerUser), icon: "bookmark.circle.fill", color: .red)
                }
                .padding(.horizontal)
            }
        case .error(let message):
            VStack(spacing: 12) {
                StatCardError(title: "Total de Usuários Únicos", icon: "person.2.fill", color: .red, message: message) {
                    fetchEpisodeAnalytics()
                }
            }
        }
    }
    
    @ViewBuilder
    private var transcriptStatusSection: some View {
        switch transcriptStatuses {
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
            .padding(.horizontal)
        case .error(let message):
            SectionErrorView(
                title: "Status de Transcrições",
                icon: "text.document",
                color: .teal,
                message: message
            ) {
                fetchTranscriptStatuses()
            }
        }
    }
    
    // MARK: - Fetch Methods
    
    private func fetchAllSections() {
        lastUpdated = Date()
        fetchActiveUsers()
        fetchDailyUserCounts()
        fetchDeviceAnalytics()
        fetchNavigationAnalytics()
        fetchRolloutData()
        fetchEpisodeAnalytics()
        fetchTranscriptStatuses()
    }
    
    private func fetchActiveUsers() {
        Task {
            activeUsers = .loading
            do {
                let count = try await repository.fetchActiveUsers(date: selectedTimeSpan.startDateString)
                await MainActor.run {
                    activeUsers = .loaded(count)
                }
            } catch {
                await MainActor.run {
                    activeUsers = .error(error.localizedDescription)
                }
            }
        }
    }
    
    private func fetchDailyUserCounts() {
        Task {
            dailyUserCounts = .loading
            do {
                let counts = try await repository.fetchDailyUserCountsLast30Days()
                await MainActor.run {
                    dailyUserCounts = .loaded(counts)
                }
            } catch {
                await MainActor.run {
                    dailyUserCounts = .error(error.localizedDescription)
                }
            }
        }
    }
    
    private func fetchDeviceAnalytics() {
        Task {
            deviceAnalytics = .loading
            do {
                let analytics = try await repository.fetchDeviceAnalytics()
                await MainActor.run {
                    deviceAnalytics = .loaded(analytics)
                }
            } catch {
                await MainActor.run {
                    deviceAnalytics = .error(error.localizedDescription)
                }
            }
        }
    }
    
    private func fetchNavigationAnalytics() {
        Task {
            navigationAnalytics = .loading
            do {
                let analytics = try await repository.fetchNavigationAnalytics()
                await MainActor.run {
                    navigationAnalytics = .loaded(analytics)
                }
            } catch {
                await MainActor.run {
                    navigationAnalytics = .error(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Release Rollout Fetch Methods
    
    private func fetchRolloutData() {
        fetchHourlyData()
        fetchDistribution()
        fetchDailyAdoption()
    }
    
    private func fetchHourlyData() {
        Task {
            hourlyData = .loading
            do {
                let dateString = formatDate(rolloutSelectedDate)
                let response = try await repository.fetchHourlyVersionData(date: dateString)
                await MainActor.run {
                    hourlyData = .loaded(response)
                }
            } catch {
                await MainActor.run {
                    hourlyData = .error(error.localizedDescription)
                }
            }
        }
    }
    
    private func fetchDistribution() {
        Task {
            distribution = .loading
            do {
                let response = try await repository.fetchVersionDistribution()
                await MainActor.run {
                    distribution = .loaded(response)
                }
            } catch {
                await MainActor.run {
                    distribution = .error(error.localizedDescription)
                }
            }
        }
    }
    
    private func fetchDailyAdoption() {
        Task {
            dailyAdoption = .loading
            do {
                let data = try await repository.fetchDailyVersionAdoption(days: 7)
                await MainActor.run {
                    dailyAdoption = .loaded(data)
                }
            } catch {
                await MainActor.run {
                    dailyAdoption = .error(error.localizedDescription)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func fetchEpisodeAnalytics() {
        Task {
            episodeAnalytics = .loading
            do {
                let response = try await repository.fetchEpisodeAnalytics()
                await MainActor.run {
                    episodeAnalytics = .loaded(response)
                }
            } catch {
                await MainActor.run {
                    episodeAnalytics = .error(error.localizedDescription)
                }
            }
        }
    }
    
    private func fetchTranscriptStatuses() {
        Task {
            transcriptStatuses = .loading
            do {
                let statuses = try await repository.fetchTranscriptStatuses()
                await MainActor.run {
                    transcriptStatuses = .loaded(statuses)
                }
            } catch {
                await MainActor.run {
                    transcriptStatuses = .error(error.localizedDescription)
                }
            }
        }
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Stat Card Component

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)
                .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 36, weight: .bold))
            }
            
            Spacer()
        }
        .padding()
        .background(platterColor)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Shared Sound Row Component

struct SharedSoundRow: View {
    let sound: SharedSoundRank
    
    var body: some View {
        HStack {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 32, height: 32)
                Text("\(sound.rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                // Sound name
                Text(sound.soundName)
                    .font(.body)
                
                // Author name
                Text(sound.authorName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Share count
            HStack(spacing: 4) {
                Image(systemName: "square.and.arrow.up")
                    .font(.caption)
                Text("\(sound.shareCount)")
                    .font(.body)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(platterColor)
        .cornerRadius(8)
    }
    
    private var rankColor: Color {
        switch sound.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .brown
        default: return .blue
        }
    }
}

// MARK: - Retro2025 Section

struct Retro2025Section: View {
    let dashboard: Retro2025DashboardResponse
    
    var body: some View {
        VStack(spacing: 20) {
            // Section Header
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.purple)
                    .font(.title2)
                Text("Retro2025")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            // Overall Stats Cards
            StatCard(
                title: "Total de Compartilhamentos",
                value: "\(dashboard.overallStats.totalShares)",
                icon: "square.and.arrow.up.fill",
                color: .purple
            )
            
            StatCard(
                title: "Usuários Únicos",
                value: "\(dashboard.overallStats.uniqueUsers)",
                icon: "person.2.fill",
                color: .blue
            )
            
            StatCard(
                title: "Média por Usuário",
                value: String(format: "%.2f", dashboard.overallStats.averageSharesPerUser),
                icon: "chart.bar.fill",
                color: .green
            )
            
            // Top Sounds
            if !dashboard.topSounds.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "music.note.list")
                            .foregroundColor(.orange)
                            .font(.title2)
                        Text("Top Sons Retro2025")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        ForEach(Array(dashboard.topSounds.enumerated()), id: \.element.id) { index, sound in
                            Retro2025SoundRow(sound: sound, rank: index + 1)
                        }
                    }
                }
                .padding()
                .background(platterColor)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            // Top Authors
            if !dashboard.topAuthors.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.3.fill")
                            .foregroundColor(.indigo)
                            .font(.title2)
                        Text("Top Autores Retro2025")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        ForEach(Array(dashboard.topAuthors.enumerated()), id: \.element.id) { index, author in
                            Retro2025AuthorRow(author: author, rank: index + 1)
                        }
                    }
                }
                .padding()
                .background(platterColor)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            // Day Patterns
            if !dashboard.dayPatterns.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.teal)
                            .font(.title2)
                        Text("Padrões por Dia da Semana")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        ForEach(dashboard.dayPatterns) { pattern in
                            Retro2025DayPatternRow(pattern: pattern)
                        }
                    }
                }
                .padding()
                .background(platterColor)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            // Top Users
            if !dashboard.topUsers.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(.pink)
                            .font(.title2)
                        Text("Top Usuários Retro2025")
                            .font(.headline)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        ForEach(Array(dashboard.topUsers.enumerated()), id: \.element.id) { index, user in
                            Retro2025UserRow(user: user, rank: index + 1)
                        }
                    }
                }
                .padding()
                .background(platterColor)
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Retro2025 Sound Row

struct Retro2025SoundRow: View {
    let sound: Retro2025SoundStat
    let rank: Int
    
    var body: some View {
        HStack {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 32, height: 32)
                Text("\(rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(sound.soundName)
                    .font(.body)
                Text("Som #\(sound.soundNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "square.and.arrow.up")
                    .font(.caption)
                Text("\(sound.shareCount)")
                    .font(.body)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(platterColor)
        .cornerRadius(8)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .brown
        default: return .blue
        }
    }
}

// MARK: - Retro2025 Author Row

struct Retro2025AuthorRow: View {
    let author: Retro2025AuthorStat
    let rank: Int
    
    var body: some View {
        HStack {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 32, height: 32)
                Text("\(rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Author image or placeholder
            if let imageURL = author.imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.secondary)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
            }
            
            Text(author.authorName)
                .font(.body)
            
            Spacer()
            
            HStack(spacing: 4) {
                Image(systemName: "square.and.arrow.up")
                    .font(.caption)
                Text("\(author.shareCount)")
                    .font(.body)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(platterColor)
        .cornerRadius(8)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .brown
        default: return .blue
        }
    }
}

// MARK: - Retro2025 Day Pattern Row

struct Retro2025DayPatternRow: View {
    let pattern: Retro2025DayOfWeekStat
    
    var body: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(.teal)
                .font(.title3)
                .frame(width: 32)
            
            Text(pattern.dayName)
                .font(.body)
            
            Spacer()
            
            Text("\(pattern.shareCount)")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(platterColor)
        .cornerRadius(8)
    }
}

// MARK: - Retro2025 User Row

struct Retro2025UserRow: View {
    let user: Retro2025UserStat
    let rank: Int
    @State private var copied = false
    
    var body: some View {
        HStack {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor)
                    .frame(width: 32, height: 32)
                Text("\(rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.userId)
                    .font(.body)
                if let mostActiveDay = user.mostActiveDay {
                    Text("Mais ativo: \(mostActiveDay)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                    Text("\(user.totalShares)")
                        .font(.body)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.secondary)
                
                Button(action: {
                    #if os(iOS)
                    UIPasteboard.general.string = user.userId
                    #elseif os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(user.userId, forType: .string)
                    #endif
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        copied = false
                    }
                }) {
                    Image(systemName: copied ? "checkmark.circle.fill" : "doc.on.doc")
                        .font(.body)
                        .foregroundColor(copied ? .green : .blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(platterColor)
        .cornerRadius(8)
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .brown
        default: return .blue
        }
    }
}

// MARK: - Daily User Count Chart

struct DailyUserCountChart: View {
    let dailyUserCounts: [DailyUserCount]
    @State private var selectedDate: Date?
    
    var selectedDataPoint: DailyUserCount? {
        guard let selectedDate = selectedDate else { return nil }
        return dailyUserCounts.first { dataPoint in
            guard let dateValue = dataPoint.dateValue else { return false }
            return Calendar.current.isDate(dateValue, inSameDayAs: selectedDate)
        }
    }
    
    var sundayDates: [Date] {
        dailyUserCounts.compactMap { dataPoint -> Date? in
            guard let date = dataPoint.dateValue else { return nil }
            return Calendar.current.component(.weekday, from: date) == 1 ? date : nil
        }
    }
    
    var fridayDates: [Date] {
        dailyUserCounts.compactMap { dataPoint -> Date? in
            guard let date = dataPoint.dateValue else { return nil }
            return Calendar.current.component(.weekday, from: date) == 6 ? date : nil
        }
    }
    
    var medianValue: Int {
        let sortedCounts = dailyUserCounts.map { $0.count }.sorted()
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
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("Usuários - Últimos 30 Dias")
                    .font(.headline)
                Spacer()
                
                // Display selected date info
                if let selected = selectedDataPoint {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formattedDate(selected.date))
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("\(selected.count) usuários")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            
            Chart {
                ForEach(dailyUserCounts) { dataPoint in
                    LineMark(
                        x: .value("Data", dataPoint.dateValue ?? Date(), unit: .day),
                        y: .value("Usuários", dataPoint.count)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Data", dataPoint.dateValue ?? Date(), unit: .day),
                        y: .value("Usuários", dataPoint.count)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue.opacity(0.3), .blue.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    // Point mark for selected date
                    if let selectedDate = selectedDate,
                       let dateValue = dataPoint.dateValue,
                       Calendar.current.isDate(dateValue, inSameDayAs: selectedDate) {
                        PointMark(
                            x: .value("Data", dateValue, unit: .day),
                            y: .value("Usuários", dataPoint.count)
                        )
                        .foregroundStyle(.blue)
                        .symbolSize(100)
                    }
                }
                
                // Vertical rule mark at selected date
                if let selectedDate = selectedDate {
                    RuleMark(x: .value("Data", selectedDate, unit: .day))
                        .foregroundStyle(.blue.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                }
                
                // Horizontal rule mark for median value
                RuleMark(y: .value("Median", medianValue))
                    .foregroundStyle(.orange.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [8, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text("Median: \(medianValue)")
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
                    AxisValueLabel(format: .dateTime.month().day(), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel()
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(platterColor)
        .cornerRadius(12)
        .padding(.horizontal)
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

// MARK: - Episode Daily Users Chart

struct EpisodeDailyUsersChart: View {
    let dailyUsers: [EpisodeDailyUserCount]
    @State private var selectedDate: Date?
    
    var selectedDataPoint: EpisodeDailyUserCount? {
        guard let selectedDate = selectedDate else { return nil }
        return dailyUsers.first { dataPoint in
            guard let dateValue = dataPoint.dateValue else { return false }
            return Calendar.current.isDate(dateValue, inSameDayAs: selectedDate)
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
                Text("Usuários Únicos - Últimos 30 Dias")
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
        .padding(.horizontal)
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

// MARK: - Episode Mini Stat Card

struct EpisodeMiniStatCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(platterColor)
        .cornerRadius(12)
    }
}

// MARK: - Transcript Status Row

struct TranscriptStatusRow: View {
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

// MARK: - Device Analytics Section

private let bogusIOSVersions: Set<String> = ["1", "19"]

/// Maps an iOS major version to the device models for which it is the last supported version.
private let lastSupportedIOSVersion: [String: Set<String>] = [
    "15": ["iPhone 6s", "iPhone 6s Plus", "iPhone 7", "iPhone 7 Plus", "iPhone SE"],
    "16": ["iPhone 8", "iPhone 8 Plus", "iPhone X"],
    "18": ["iPhone XR", "iPhone XS", "iPhone XS Max"],
    "26": ["iPhone 11", "iPhone 11 Pro", "iPhone 11 Pro Max", "iPhone SE (2nd generation)"],
]

struct DeviceAnalyticsSection: View {
    let analytics: DeviceAnalyticsResponse
    let repository: AnalyticsRepositoryProtocol
    @State private var showAllDeviceModels = false
    @State private var selectedModel: DeviceModelStat?
    @State private var showCombinedChart = false
    @State private var showModelSearch = false
    @State private var selectedVersion: IOSVersionStat?
    @State private var showCombinedVersionChart = false
    @State private var showVersionSearch = false

    private var filteredIOSVersions: [IOSVersionStat] {
        analytics.topIOSVersions.filter { !bogusIOSVersions.contains($0.majorVersion) }
    }

    init(analytics: DeviceAnalyticsResponse, repository: AnalyticsRepositoryProtocol) {
        self.analytics = analytics
        self.repository = repository
        print("🔍 [DeviceAnalyticsSection] Initialized")
        print("   - iOS Versions: \(analytics.topIOSVersions.count) items")
        print("   - Device Models: \(analytics.topDeviceModels.count) items")
        print("   - Device Types: \(analytics.topDeviceTypes.count) items")
        print("   - Timezones: \(analytics.topTimezones.count) items")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section Header
            HStack {
                Image(systemName: "iphone")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("Dispositivos e Sistema")
                    .font(.headline)
            }
            .padding(.horizontal)
            .onAppear {
                print("🔍 [DeviceAnalyticsSection] Header appeared")
            }
            
            // Top iOS Versions
            if !filteredIOSVersions.isEmpty {
                let totalIOSVersions = filteredIOSVersions.reduce(0) { $0 + $1.count }
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "app.badge")
                            .foregroundColor(.blue)
                            .font(.title3)
                        Text("Versões iOS")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        ForEach(filteredIOSVersions) { version in
                            Button {
                                selectedVersion = version
                            } label: {
                                IOSVersionRow(version: version, totalCount: totalIOSVersions)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    let versionsPct = totalIOSVersions > 0
                        ? 100.0
                        : 0.0
                    Text("As \(filteredIOSVersions.count) versões exibidas representam \(String(format: "%.1f", versionsPct))% do total.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    HStack(spacing: 12) {
                        Button {
                            showCombinedVersionChart = true
                        } label: {
                            HStack {
                                Image(systemName: "chart.xyaxis.line")
                                Text("Ver Todos Combinados")
                            }
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                        
                        Button {
                            showVersionSearch = true
                        } label: {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Buscar Versão")
                            }
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.blue)
                    }
                    .padding(.top, 4)
                }
                .padding()
                .background(platterColor)
                .cornerRadius(12)
                .padding(.horizontal)
                .onAppear {
                    print("🔍 [DeviceAnalyticsSection] iOS Versions section appeared (total: \(totalIOSVersions))")
                }
            }
            
            // Top Device Models
            if !analytics.topDeviceModels.isEmpty {
                let totalDeviceModels = analytics.topDeviceModels.reduce(0) { $0 + $1.count }
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "iphone")
                            .foregroundColor(.green)
                            .font(.title3)
                        Text("Modelos de Dispositivo")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        let visibleModels = showAllDeviceModels
                            ? analytics.topDeviceModels
                            : Array(analytics.topDeviceModels.prefix(5))
                        ForEach(Array(visibleModels.enumerated()), id: \.element.id) { index, model in
                            Button {
                                selectedModel = model
                            } label: {
                                DeviceModelRow(model: model, rank: index + 1, totalCount: totalDeviceModels)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    let visibleCount = showAllDeviceModels
                        ? analytics.topDeviceModels.count
                        : min(5, analytics.topDeviceModels.count)
                    let visibleSum = analytics.topDeviceModels.prefix(visibleCount).reduce(0) { $0 + $1.count }
                    let visiblePct = totalDeviceModels > 0
                        ? Double(visibleSum) / Double(totalDeviceModels) * 100
                        : 0
                    
                    Text("Os \(visibleCount) dispositivos exibidos representam \(String(format: "%.1f", visiblePct))% do total.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    if analytics.topDeviceModels.count > 5 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showAllDeviceModels.toggle()
                            }
                        } label: {
                            HStack {
                                Text(showAllDeviceModels ? "Mostrar menos" : "Mostrar mais")
                                Image(systemName: showAllDeviceModels ? "chevron.up" : "chevron.down")
                            }
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    HStack(spacing: 12) {
                        Button {
                            showCombinedChart = true
                        } label: {
                            HStack {
                                Image(systemName: "chart.xyaxis.line")
                                Text("Ver Todos Combinados")
                            }
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)
                        
                        Button {
                            showModelSearch = true
                        } label: {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                Text("Buscar Modelo")
                            }
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)
                    }
                    .padding(.top, 4)
                }
                .padding()
                .background(platterColor)
                .cornerRadius(12)
                .padding(.horizontal)
                .onAppear {
                    print("🔍 [DeviceAnalyticsSection] Device Models section appeared (total: \(totalDeviceModels))")
                }
            }
            
            // Top Device Types
            if !analytics.topDeviceTypes.isEmpty {
                let totalDeviceTypes = analytics.topDeviceTypes.reduce(0) { $0 + $1.count }
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "devices")
                            .foregroundColor(.purple)
                            .font(.title3)
                        Text("Tipos de Dispositivo")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        ForEach(analytics.topDeviceTypes) { type in
                            DeviceTypeRow(type: type, totalCount: totalDeviceTypes)
                        }
                    }
                }
                .padding()
                .background(platterColor)
                .cornerRadius(12)
                .padding(.horizontal)
                .onAppear {
                    print("🔍 [DeviceAnalyticsSection] Device Types section appeared (total: \(totalDeviceTypes))")
                }
            }
            
            // Top Timezones
            if !analytics.topTimezones.isEmpty {
                TimezonePieChart(
                    timezones: analytics.topTimezones,
                    totalCount: analytics.totalTimezonesCount
                )
            }
        }
        .onAppear {
            print("🔍 [DeviceAnalyticsSection] Full section appeared")
        }
        .sheet(item: $selectedModel) { model in
            DeviceModelHistorySheet(
                modelName: model.modelName,
                repository: repository
            )
        }
        .sheet(isPresented: $showCombinedChart) {
            DeviceModelCombinedSheet(
                models: analytics.topDeviceModels,
                repository: repository
            )
        }
        .sheet(isPresented: $showModelSearch) {
            DeviceModelSearchSheet(repository: repository)
        }
        .sheet(item: $selectedVersion) { version in
            IOSVersionHistorySheet(
                majorVersion: version.majorVersion,
                repository: repository
            )
        }
        .sheet(isPresented: $showCombinedVersionChart) {
            IOSVersionCombinedSheet(
                versions: filteredIOSVersions,
                repository: repository
            )
        }
        .sheet(isPresented: $showVersionSearch) {
            IOSVersionSearchSheet(repository: repository)
        }
    }
}

// MARK: - Device Model History Sheet

struct DeviceModelHistorySheet: View {
    let modelName: String
    let repository: AnalyticsRepositoryProtocol
    @State private var historyState: LoadingState<DeviceModelHistoryResponse> = .loading
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(modelName)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("% do total de usuários ao longo do tempo")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            switch historyState {
            case .loading:
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                Spacer()
            case .loaded(let response):
                if response.history.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Sem dados históricos para este dispositivo.")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    DeviceModelHistoryChart(history: response.history)
                        .padding()
                }
            case .error(let message):
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Tentar Novamente") {
                        fetchHistory()
                    }
                    .buttonStyle(.bordered)
                }
                Spacer()
            }
        }
        .frame(width: 900, height: 600)
        .onAppear {
            fetchHistory()
        }
    }

    private func fetchHistory() {
        Task {
            historyState = .loading
            do {
                let response = try await repository.fetchDeviceModelHistory(modelName: modelName)
                await MainActor.run {
                    historyState = .loaded(response)
                }
            } catch {
                await MainActor.run {
                    historyState = .error(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Device Model History Chart

struct DeviceModelHistoryChart: View {
    let history: [DeviceModelMonthlyCount]
    @State private var selectedMonth: Date?
    @State private var showTrendLine = false

    var selectedDataPoint: DeviceModelMonthlyCount? {
        guard let selectedMonth else { return nil }
        return history.first { dataPoint in
            guard let dateValue = dataPoint.dateValue else { return false }
            return Calendar.current.isDate(dateValue, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    var medianCount: Int {
        let sorted = history.map(\.count).filter { $0 > 0 }.sorted()
        let n = sorted.count
        if n == 0 {
            return 0
        } else if n % 2 == 0 {
            return (sorted[n / 2 - 1] + sorted[n / 2]) / 2
        } else {
            return sorted[n / 2]
        }
    }

    var medianAsPercentage: Double {
        guard medianCount > 0 else { return 0 }
        let nearestMonth = history.min(by: { abs($0.count - medianCount) < abs($1.count - medianCount) })
        return nearestMonth?.percentage ?? 0
    }

    var trendLine: [(date: Date, value: Double)] {
        let points: [(x: Double, y: Double, date: Date)] = history.compactMap { entry in
            guard let date = entry.dateValue else { return nil }
            return (x: date.timeIntervalSince1970, y: entry.percentage, date: date)
        }
        guard points.count >= 2 else { return [] }

        let n = Double(points.count)
        let sumX = points.reduce(0.0) { $0 + $1.x }
        let sumY = points.reduce(0.0) { $0 + $1.y }
        let sumXY = points.reduce(0.0) { $0 + $1.x * $1.y }
        let sumX2 = points.reduce(0.0) { $0 + $1.x * $1.x }

        let denominator = n * sumX2 - sumX * sumX
        guard denominator != 0 else { return [] }

        let slope = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n

        return points.map { p in
            (date: p.date, value: slope * p.x + intercept)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("% do Total de Usuários por Mês")
                    .font(.headline)
                Spacer()

                if let selected = selectedDataPoint {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(formattedMonth(selected.month))
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("\(String(format: "%.1f", selected.percentage))% (\(selected.count) de \(selected.total))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showTrendLine.toggle()
                    }
                } label: {
                    Image(systemName: showTrendLine ? "line.diagonal" : "line.diagonal")
                        .foregroundColor(showTrendLine ? .blue : .secondary)
                        .padding(6)
                        .background(showTrendLine ? Color.blue.opacity(0.15) : Color.clear)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help("Linha de tendência")
            }

            Chart {
                ForEach(history) { dataPoint in
                    LineMark(
                        x: .value("Mês", dataPoint.dateValue ?? Date(), unit: .month),
                        y: .value("%", dataPoint.percentage)
                    )
                    .foregroundStyle(.green)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Mês", dataPoint.dateValue ?? Date(), unit: .month),
                        y: .value("%", dataPoint.percentage)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green.opacity(0.3), .green.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    if let selectedMonth,
                       let dateValue = dataPoint.dateValue,
                       Calendar.current.isDate(dateValue, equalTo: selectedMonth, toGranularity: .month) {
                        PointMark(
                            x: .value("Mês", dateValue, unit: .month),
                            y: .value("%", dataPoint.percentage)
                        )
                        .foregroundStyle(.green)
                        .symbolSize(100)
                    }
                }

                if let selectedMonth {
                    RuleMark(x: .value("Mês", selectedMonth, unit: .month))
                        .foregroundStyle(.green.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                }

                if medianCount > 0 {
                    RuleMark(y: .value("Mediana", medianAsPercentage))
                        .foregroundStyle(.orange.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [8, 4]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Mediana: \(medianCount) usuários")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                                .padding(4)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(4)
                        }
                }

                if showTrendLine {
                    let trend = trendLine
                    ForEach(Array(trend.enumerated()), id: \.offset) { _, point in
                        LineMark(
                            x: .value("Mês", point.date, unit: .month),
                            y: .value("Tendência", point.value)
                        )
                        .foregroundStyle(.blue.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 3]))
                    }
                }
            }
            .chartXSelection(value: $selectedMonth)
            .chartXAxis {
                let strideCount = history.count > 18 ? 3 : (history.count > 10 ? 2 : 1)
                AxisMarks(values: .stride(by: .month, count: strideCount)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).year(.twoDigits), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    if let pct = value.as(Double.self) {
                        AxisValueLabel {
                            Text("\(String(format: "%.0f", pct))%")
                        }
                    }
                }
            }
            .frame(height: 250)
        }
    }

    private func formattedMonth(_ monthString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        guard let date = formatter.date(from: monthString) else { return monthString }
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMMM yyyy"
        return displayFormatter.string(from: date)
    }
}

// MARK: - Combined Device Model Data Point

struct CombinedModelDataPoint: Identifiable {
    var id: String { "\(modelName)-\(month)" }
    let modelName: String
    let month: String
    let percentage: Double
    var count: Int?

    var dateValue: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.date(from: month)
    }
}

// MARK: - Device Model Combined Sheet

struct DeviceModelCombinedSheet: View {
    let models: [DeviceModelStat]
    let repository: AnalyticsRepositoryProtocol
    @State private var dataPoints: [CombinedModelDataPoint] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    private let colorPalette: [Color] = [
        .blue, .orange, .green, .red, .purple,
        .pink, .yellow, .teal, .indigo, .cyan
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Top \(models.count) Dispositivos - Evolução")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("% do total de usuários ao longo do tempo")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            if isLoading {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                Spacer()
            } else if let errorMessage {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Tentar Novamente") {
                        fetchAll()
                    }
                    .buttonStyle(.bordered)
                }
                Spacer()
            } else if dataPoints.isEmpty {
                Spacer()
                Text("Sem dados disponíveis.")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                let modelNames = models.map(\.modelName)
                let colorRange = modelNames.indices.map { colorPalette[$0 % colorPalette.count] }

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        let months = Set(dataPoints.map(\.month)).sorted()
                        let strideCount = months.count > 18 ? 3 : (months.count > 10 ? 2 : 1)

                        Chart(dataPoints) { point in
                            AreaMark(
                                x: .value("Mês", point.dateValue ?? Date(), unit: .month),
                                y: .value("%", point.percentage)
                            )
                            .foregroundStyle(by: .value("Modelo", point.modelName))
                            .interpolationMethod(.catmullRom)
                        }
                        .chartForegroundStyleScale(domain: modelNames, range: colorRange)
                        .chartLegend(.hidden)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .month, count: strideCount)) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.month(.abbreviated).year(.twoDigits), centered: true)
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisGridLine()
                                if let pct = value.as(Double.self) {
                                    AxisValueLabel {
                                        Text("\(String(format: "%.0f", pct))%")
                                    }
                                }
                            }
                        }
                        .frame(height: 350)
                        .padding()

                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(modelNames.enumerated()), id: \.element) { index, name in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(colorPalette[index % colorPalette.count])
                                        .frame(width: 10, height: 10)
                                    Text(name)
                                        .font(.caption)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
            }
        }
        .frame(width: 900, height: 600)
        .onAppear {
            fetchAll()
        }
    }

    private func fetchAll() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                let results = try await withThrowingTaskGroup(of: DeviceModelHistoryResponse.self, returning: [DeviceModelHistoryResponse].self) { group in
                    for model in models {
                        group.addTask {
                            try await repository.fetchDeviceModelHistory(modelName: model.modelName)
                        }
                    }
                    var collected: [DeviceModelHistoryResponse] = []
                    for try await result in group {
                        collected.append(result)
                    }
                    return collected
                }

                let points = results.flatMap { response in
                    response.history.map { entry in
                        CombinedModelDataPoint(
                            modelName: response.modelName,
                            month: entry.month,
                            percentage: entry.percentage
                        )
                    }
                }

                await MainActor.run {
                    dataPoints = points.sorted { $0.month < $1.month }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Device Model Search Sheet

struct DeviceModelSearchSheet: View {
    let repository: AnalyticsRepositoryProtocol
    @State private var allModelNames: LoadingState<[String]> = .loading
    @State private var selectedModelName: String?
    @State private var historyState: HistoryState = .idle
    @Environment(\.dismiss) private var dismiss

    enum HistoryState {
        case idle
        case loading
        case loaded(DeviceModelHistoryResponse)
        case error(String)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Buscar Modelo")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Selecione um modelo para ver seu histórico")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            switch allModelNames {
            case .loading:
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Carregando modelos...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom)
            case .loaded(let names):
                let grouped = Self.groupDeviceModels(names)

                HStack {
                    Picker("Modelo", selection: $selectedModelName) {
                        Text("Selecione um modelo...")
                            .tag(nil as String?)

                        ForEach(grouped, id: \.label) { group in
                            if !group.models.isEmpty {
                                Section(group.label) {
                                    ForEach(group.models, id: \.self) { name in
                                        Text(name).tag(name as String?)
                                    }
                                }
                            }
                        }
                    }
                    .labelsHidden()
                    .onChange(of: selectedModelName) { _, newValue in
                        if let name = newValue {
                            fetchHistory(for: name)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            case .error(let message):
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Tentar Novamente") {
                        loadModelNames()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }

            Divider()

            Group {
                switch historyState {
                case .idle:
                    VStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "iphone")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("Selecione um modelo acima para ver o histórico.")
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                case .loading:
                    VStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Spacer()
                    }
                case .loaded(let response):
                    if response.history.isEmpty {
                        VStack {
                            Spacer()
                            VStack(spacing: 12) {
                                Image(systemName: "chart.line.downtrend.xyaxis")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("Sem dados históricos para este modelo.")
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(response.modelName)
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top)
                            DeviceModelHistoryChart(history: response.history)
                                .padding()
                        }
                    }
                case .error(let message):
                    VStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text(message)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Tentar Novamente") {
                                if let name = selectedModelName {
                                    fetchHistory(for: name)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 900, height: 600)
        .onAppear {
            loadModelNames()
        }
    }

    private func loadModelNames() {
        Task {
            allModelNames = .loading
            do {
                let names = try await repository.fetchAllDeviceModelNames()
                await MainActor.run {
                    allModelNames = .loaded(names)
                }
            } catch {
                await MainActor.run {
                    allModelNames = .error(error.localizedDescription)
                }
            }
        }
    }

    private func fetchHistory(for modelName: String) {
        Task {
            historyState = .loading
            do {
                let response = try await repository.fetchDeviceModelHistory(modelName: modelName)
                await MainActor.run {
                    historyState = .loaded(response)
                }
            } catch {
                await MainActor.run {
                    historyState = .error(error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Device Grouping

    struct DeviceGroup {
        let label: String
        let models: [String]
    }

    private static let yearDevices: [(year: Int, devices: [String])] = [
        (2014, ["iPad Air 2"]),
        (2015, ["iPhone 6s", "iPhone 6s Plus", "iPad mini 4", "iPad Pro (12.9-inch) (1st generation)"]),
        (2016, ["iPhone 7", "iPhone 7 Plus", "iPhone SE", "iPad Pro (9.7-inch)"]),
        (2017, ["iPhone 8", "iPhone 8 Plus", "iPhone X", "iPad (5th generation)", "iPad Pro (10.5-inch)", "iPad Pro (12.9-inch) (2nd generation)"]),
        (2018, ["iPhone XR", "iPhone XS", "iPhone XS Max", "iPad (6th generation)", "iPad Pro (11-inch) (1st generation)", "iPad Pro (12.9-inch) (3rd generation)"]),
        (2019, ["iPhone 11", "iPhone 11 Pro", "iPhone 11 Pro Max", "iPod touch (7th generation)", "iPad mini (5th generation)", "iPad (7th generation)", "iPad Air (3rd generation)"]),
        (2020, ["iPhone 12", "iPhone 12 mini", "iPhone 12 Pro", "iPhone 12 Pro Max", "iPhone SE (2nd generation)", "iPad (8th generation)", "iPad Air (4th generation)", "iPad Pro (11-inch) (2nd generation)", "iPad Pro (12.9-inch) (4th generation)"]),
        (2021, ["iPhone 13", "iPhone 13 mini", "iPhone 13 Pro", "iPhone 13 Pro Max", "iPad mini (6th generation)", "iPad (9th generation)", "iPad Air (5th generation)", "iPad Pro (11-inch) (3rd generation)", "iPad Pro (12.9-inch) (5th generation)"]),
        (2022, ["iPhone 14", "iPhone 14 Plus", "iPhone 14 Pro", "iPhone 14 Pro Max", "iPhone SE (3rd generation)", "iPad (10th generation)", "iPad Pro (12.9-inch) (6th generation)", "iPad Pro (11-inch) (4th generation)"]),
        (2023, ["iPhone 15", "iPhone 15 Plus", "iPhone 15 Pro", "iPhone 15 Pro Max"]),
        (2024, ["iPhone 16", "iPhone 16 Plus", "iPhone 16 Pro", "iPhone 16 Pro Max", "iPad mini (A17 Pro)", "iPad Air 11-inch (M2)", "iPad Air 13-inch (M2)", "iPad Pro 11-inch (M4)", "iPad Pro 13-inch (M4)"]),
        (2025, ["iPhone 16e", "iPhone 17", "iPhone 17 Pro", "iPhone 17 Pro Max", "iPhone Air", "iPad (A16)", "iPad Air 11-inch (M3)", "iPad Air 13-inch (M3)"]),
        (2026, ["iPhone 17e"]),
    ]

    static func groupDeviceModels(_ names: [String]) -> [DeviceGroup] {
        let filtered = names.filter { !$0.hasPrefix("Simulator") }

        let otherPrefixes = ["Apple TV", "Apple Vision", "Mac"]
        let rawPattern = /^[A-Za-z]+\d+,\d+$/

        let isOther: (String) -> Bool = { name in otherPrefixes.contains { name.hasPrefix($0) } }
        let isRaw: (String) -> Bool = { name in name.wholeMatch(of: rawPattern) != nil }

        let assignedToYear = Set(yearDevices.flatMap(\.devices))

        var groups: [DeviceGroup] = []

        for (year, devices) in yearDevices {
            let matching = filtered.filter { devices.contains($0) }
            let sorted = matching.sorted { a, b in
                let aIsIPhone = a.hasPrefix("iPhone")
                let bIsIPhone = b.hasPrefix("iPhone")
                if aIsIPhone != bIsIPhone { return aIsIPhone }
                return a < b
            }
            groups.append(DeviceGroup(label: "\(year)", models: sorted))
        }

        let ungrouped = filtered.filter { name in
            !isOther(name) && !isRaw(name) && !assignedToYear.contains(name)
        }
        if !ungrouped.isEmpty {
            groups.insert(DeviceGroup(label: "Sem Ano", models: ungrouped), at: 0)
        }

        groups.append(DeviceGroup(label: "Outros", models: filtered.filter { isOther($0) }))
        groups.append(DeviceGroup(label: "Raw", models: filtered.filter { isRaw($0) }))

        return groups
    }
}

// MARK: - iOS Version History Sheet

struct IOSVersionHistorySheet: View {
    let majorVersion: String
    let repository: AnalyticsRepositoryProtocol
    @State private var historyState: LoadingState<IOSVersionHistoryResponse> = .loading
    @State private var breakdownState: LoadingState<IOSVersionDeviceBreakdownResponse> = .loading
    @State private var selectedTab = 0
    @State private var hoveredDate: Date?
    @Environment(\.dismiss) private var dismiss

    private let colorPalette: [Color] = [
        .blue, .orange, .green, .red, .purple,
        .pink, .yellow, .teal, .indigo, .cyan
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("iOS \(majorVersion)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("% do total de usuários ao longo do tempo")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Picker("", selection: $selectedTab) {
                Text("Tendência").tag(0)
                Text("Dispositivos").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            Divider()

            if selectedTab == 0 {
                switch historyState {
                case .loading:
                    Spacer()
                    ProgressView().scaleEffect(1.5)
                    Spacer()
                case .loaded(let response):
                    if response.history.isEmpty {
                        Spacer()
                        emptyView("Sem dados históricos para esta versão.")
                        Spacer()
                    } else {
                        DeviceModelHistoryChart(history: response.history)
                            .padding()
                    }
                case .error(let message):
                    Spacer()
                    errorView(message) { fetchHistory() }
                    Spacer()
                }
            } else {
                switch breakdownState {
                case .loading:
                    Spacer()
                    ProgressView().scaleEffect(1.5)
                    Spacer()
                case .loaded(let response):
                    if response.devices.isEmpty {
                        Spacer()
                        emptyView("Sem dados de dispositivos para esta versão.")
                        Spacer()
                    } else {
                        deviceBreakdownChart(response: response)
                    }
                case .error(let message):
                    Spacer()
                    errorView(message) { fetchBreakdown() }
                    Spacer()
                }
            }
        }
        .frame(width: 900, height: 600)
        .onAppear {
            fetchHistory()
            fetchBreakdown()
        }
    }

    @ViewBuilder
    private func deviceBreakdownChart(response: IOSVersionDeviceBreakdownResponse) -> some View {
        let topDevices = Array(response.devices.prefix(10))
        let deviceNames = topDevices.map(\.modelName)
        let colorRange = deviceNames.indices.map { colorPalette[$0 % colorPalette.count] }

        let dataPoints: [CombinedModelDataPoint] = topDevices.flatMap { device in
            let totalPerMonth: [String: Int] = {
                var totals: [String: Int] = [:]
                for d in topDevices {
                    for entry in d.history {
                        totals[entry.month, default: 0] += entry.count
                    }
                }
                return totals
            }()
            return device.history.map { entry in
                let total = totalPerMonth[entry.month] ?? 1
                let pct = Double(entry.count) / Double(total) * 100
                return CombinedModelDataPoint(
                    modelName: device.modelName,
                    month: entry.month,
                    percentage: pct,
                    count: entry.count
                )
            }
        }
        .sorted { $0.month < $1.month }

        let months = Set(dataPoints.map(\.month)).sorted()
        let strideCount = months.count > 18 ? 3 : (months.count > 10 ? 2 : 1)

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Chart(dataPoints) { point in
                    AreaMark(
                        x: .value("Mês", point.dateValue ?? Date(), unit: .month),
                        y: .value("%", point.percentage)
                    )
                    .foregroundStyle(by: .value("Modelo", point.modelName))
                    .interpolationMethod(.catmullRom)
                }
                .chartForegroundStyleScale(domain: deviceNames, range: colorRange)
                .chartLegend(.hidden)
                .chartXSelection(value: $hoveredDate)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month, count: strideCount)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).year(.twoDigits), centered: true)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        if let pct = value.as(Double.self) {
                            AxisValueLabel {
                                Text("\(String(format: "%.0f", pct))%")
                            }
                        }
                    }
                }
                .frame(height: 350)
                .padding()

                let endOfLifeDevices = lastSupportedIOSVersion[majorVersion] ?? []

                if let hoveredDate {
                    let hoveredMonth: String = {
                        let fmt = DateFormatter()
                        fmt.dateFormat = "yyyy-MM"
                        return fmt.string(from: hoveredDate)
                    }()
                    let hoveredPoints = dataPoints
                        .filter { $0.month == hoveredMonth }
                        .sorted { $0.percentage > $1.percentage }

                    if !hoveredPoints.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(formattedMonth(hoveredMonth))
                                .font(.caption)
                                .fontWeight(.semibold)

                            ForEach(hoveredPoints, id: \.modelName) { point in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(colorForDevice(point.modelName, in: deviceNames))
                                        .frame(width: 10, height: 10)
                                    Text(point.modelName)
                                        .font(.caption)
                                    if endOfLifeDevices.contains(point.modelName) {
                                        Text("Última versão")
                                            .font(.system(size: 9, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(.red))
                                    }
                                    Spacer()
                                    if let count = point.count {
                                        Text("\(count)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Text(String(format: "%.1f%%", point.percentage))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(nsColor: .controlBackgroundColor)))
                        .padding(.horizontal)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(deviceNames.enumerated()), id: \.element) { index, name in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(colorPalette[index % colorPalette.count])
                                .frame(width: 10, height: 10)
                            Text(name)
                                .font(.caption)
                            if endOfLifeDevices.contains(name) {
                                Text("Última versão")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(.red))
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
    }

    @ViewBuilder
    private func emptyView(_ text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.downtrend.xyaxis")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(text)
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private func errorView(_ message: String, retry: @escaping () -> Void) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Tentar Novamente", action: retry)
                .buttonStyle(.bordered)
        }
    }

    private func fetchHistory() {
        Task {
            historyState = .loading
            do {
                let response = try await repository.fetchIOSVersionHistory(majorVersion: majorVersion)
                await MainActor.run { historyState = .loaded(response) }
            } catch {
                await MainActor.run { historyState = .error(error.localizedDescription) }
            }
        }
    }

    private func fetchBreakdown() {
        Task {
            breakdownState = .loading
            do {
                let response = try await repository.fetchIOSVersionDeviceBreakdown(majorVersion: majorVersion)
                await MainActor.run { breakdownState = .loaded(response) }
            } catch {
                await MainActor.run { breakdownState = .error(error.localizedDescription) }
            }
        }
    }

    private func formattedMonth(_ monthString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        guard let date = formatter.date(from: monthString) else { return monthString }
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMMM yyyy"
        return displayFormatter.string(from: date)
    }

    private func colorForDevice(_ name: String, in deviceNames: [String]) -> Color {
        guard let idx = deviceNames.firstIndex(of: name) else { return .gray }
        return colorPalette[idx % colorPalette.count]
    }
}

// MARK: - iOS Version Combined Sheet

struct IOSVersionCombinedSheet: View {
    let versions: [IOSVersionStat]
    let repository: AnalyticsRepositoryProtocol
    @State private var dataPoints: [CombinedModelDataPoint] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    private let colorPalette: [Color] = [
        .blue, .orange, .green, .red, .purple,
        .pink, .yellow, .teal, .indigo, .cyan
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Todas as Versões iOS - Evolução")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("% do total de usuários ao longo do tempo")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            if isLoading {
                Spacer()
                ProgressView().scaleEffect(1.5)
                Spacer()
            } else if let errorMessage {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Tentar Novamente") { fetchAll() }
                        .buttonStyle(.bordered)
                }
                Spacer()
            } else if dataPoints.isEmpty {
                Spacer()
                Text("Sem dados disponíveis.")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                let versionNames = versions.map { "iOS \($0.majorVersion)" }
                let colorRange = versionNames.indices.map { colorPalette[$0 % colorPalette.count] }

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        let months = Set(dataPoints.map(\.month)).sorted()
                        let strideCount = months.count > 18 ? 3 : (months.count > 10 ? 2 : 1)

                        Chart(dataPoints) { point in
                            AreaMark(
                                x: .value("Mês", point.dateValue ?? Date(), unit: .month),
                                y: .value("%", point.percentage)
                            )
                            .foregroundStyle(by: .value("Versão", point.modelName))
                            .interpolationMethod(.catmullRom)
                        }
                        .chartForegroundStyleScale(domain: versionNames, range: colorRange)
                        .chartLegend(.hidden)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .month, count: strideCount)) { _ in
                                AxisGridLine()
                                AxisValueLabel(format: .dateTime.month(.abbreviated).year(.twoDigits), centered: true)
                            }
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                AxisGridLine()
                                if let pct = value.as(Double.self) {
                                    AxisValueLabel {
                                        Text("\(String(format: "%.0f", pct))%")
                                    }
                                }
                            }
                        }
                        .frame(height: 350)
                        .padding()

                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(versionNames.enumerated()), id: \.element) { index, name in
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(colorPalette[index % colorPalette.count])
                                        .frame(width: 10, height: 10)
                                    Text(name)
                                        .font(.caption)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
            }
        }
        .frame(width: 900, height: 600)
        .onAppear { fetchAll() }
    }

    private func fetchAll() {
        Task {
            isLoading = true
            errorMessage = nil

            do {
                let results = try await withThrowingTaskGroup(of: IOSVersionHistoryResponse.self, returning: [IOSVersionHistoryResponse].self) { group in
                    for version in versions {
                        group.addTask {
                            try await repository.fetchIOSVersionHistory(majorVersion: version.majorVersion)
                        }
                    }
                    var collected: [IOSVersionHistoryResponse] = []
                    for try await result in group {
                        collected.append(result)
                    }
                    return collected
                }

                let points = results.flatMap { response in
                    response.history.map { entry in
                        CombinedModelDataPoint(
                            modelName: "iOS \(response.majorVersion)",
                            month: entry.month,
                            percentage: entry.percentage
                        )
                    }
                }

                await MainActor.run {
                    dataPoints = points.sorted { $0.month < $1.month }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - iOS Version Search Sheet

struct IOSVersionSearchSheet: View {
    let repository: AnalyticsRepositoryProtocol
    @State private var allVersions: LoadingState<[String]> = .loading
    @State private var selectedVersion: String?
    @State private var historyState: LoadingState<IOSVersionHistoryResponse> = .loading
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Buscar Versão iOS")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Selecione uma versão para ver seu histórico")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            switch allVersions {
            case .loading:
                HStack {
                    ProgressView().controlSize(.small)
                    Text("Carregando versões...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom)
            case .loaded(let versions):
                HStack {
                    Picker("Versão", selection: $selectedVersion) {
                        Text("Selecione uma versão...")
                            .tag(nil as String?)
                        ForEach(versions, id: \.self) { version in
                            Text("iOS \(version)").tag(version as String?)
                        }
                    }
                    .labelsHidden()
                    .onChange(of: selectedVersion) { _, newValue in
                        if let version = newValue {
                            fetchHistory(for: version)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            case .error(let message):
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Tentar Novamente") { loadVersions() }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }

            Divider()

            Group {
                switch historyState {
                case .loading:
                    if selectedVersion == nil {
                        VStack {
                            Spacer()
                            VStack(spacing: 12) {
                                Image(systemName: "app.badge")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("Selecione uma versão acima para ver o histórico.")
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    } else {
                        VStack {
                            Spacer()
                            ProgressView().scaleEffect(1.5)
                            Spacer()
                        }
                    }
                case .loaded(let response):
                    if response.history.isEmpty {
                        VStack {
                            Spacer()
                            VStack(spacing: 12) {
                                Image(systemName: "chart.line.downtrend.xyaxis")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("Sem dados históricos para esta versão.")
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("iOS \(response.majorVersion)")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top)
                            DeviceModelHistoryChart(history: response.history)
                                .padding()
                        }
                    }
                case .error(let message):
                    VStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            Text(message)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("Tentar Novamente") {
                                if let v = selectedVersion { fetchHistory(for: v) }
                            }
                            .buttonStyle(.bordered)
                        }
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 900, height: 600)
        .onAppear { loadVersions() }
    }

    private func loadVersions() {
        Task {
            allVersions = .loading
            do {
                let versions = try await repository.fetchAllIOSVersions()
                    .filter { !bogusIOSVersions.contains($0) }
                await MainActor.run { allVersions = .loaded(versions) }
            } catch {
                await MainActor.run { allVersions = .error(error.localizedDescription) }
            }
        }
    }

    private func fetchHistory(for majorVersion: String) {
        Task {
            historyState = .loading
            do {
                let response = try await repository.fetchIOSVersionHistory(majorVersion: majorVersion)
                await MainActor.run { historyState = .loaded(response) }
            } catch {
                await MainActor.run { historyState = .error(error.localizedDescription) }
            }
        }
    }
}

// MARK: - iOS Version Row

struct IOSVersionRow: View {
    let version: IOSVersionStat
    let totalCount: Int
    
    var percentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(version.count) / Double(totalCount) * 100
    }
    
    var body: some View {
        HStack {
            Image(systemName: "app.badge")
                .foregroundColor(.blue)
                .font(.title3)
                .frame(width: 32)
            
            Text(version.displayName)
                .font(.body)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("\(version.count)")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text("(\(String(format: "%.1f", percentage))%)")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(platterColor)
        .cornerRadius(8)
    }
}

// MARK: - Device Model Row

struct DeviceModelRow: View {
    let model: DeviceModelStat
    let rank: Int
    let totalCount: Int
    
    var percentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(model.count) / Double(totalCount) * 100
    }
    
    var body: some View {
        HStack {
            Text("\(rank)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(width: 24, alignment: .center)
            
            Image(systemName: "iphone")
                .foregroundColor(.green)
                .font(.title3)
                .frame(width: 32)
            
            Text(model.modelName)
                .font(.body)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("\(model.count)")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text("(\(String(format: "%.1f", percentage))%)")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(platterColor)
        .cornerRadius(8)
    }
}

// MARK: - Device Type Row

struct DeviceTypeRow: View {
    let type: DeviceTypeStat
    let totalCount: Int
    
    var percentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(type.count) / Double(totalCount) * 100
    }
    
    var body: some View {
        HStack {
            Image(systemName: type.iconName)
                .foregroundColor(.purple)
                .font(.title3)
                .frame(width: 32)
            
            Text(type.deviceType)
                .font(.body)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("\(type.count)")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text("(\(String(format: "%.1f", percentage))%)")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(platterColor)
        .cornerRadius(8)
    }
}

// MARK: - Timezone Pie Chart

struct TimezonePieChart: View {
    let timezones: [TimezoneStat]
    let totalCount: Int
    @State private var selectedTimezone: String?
    @State private var hoveredTimezone: String?
    
    // Color palette for timezones
    private let colors: [Color] = [
        .blue, .orange, .green, .purple, .pink,
        .red, .yellow, .teal, .indigo, .cyan
    ]
    
    private func color(for timezone: String) -> Color {
        let index = timezones.firstIndex(where: { $0.timezone == timezone }) ?? 0
        return colors[index % colors.count]
    }
    
    private func percentage(for timezone: TimezoneStat) -> Double {
        guard totalCount > 0 else { return 0 }
        return Double(timezone.count) / Double(totalCount) * 100
    }
    
    var selectedTimezoneStat: TimezoneStat? {
        let active = selectedTimezone ?? hoveredTimezone
        guard let active = active else { return nil }
        return timezones.first { $0.timezone == active }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(.orange)
                    .font(.title3)
                Text("Fusos Horários")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                
                // Show selected timezone info
                if let selected = selectedTimezoneStat {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(selected.timezone)
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("\(selected.count) (\(String(format: "%.1f", percentage(for: selected)))%)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            
            Chart {
                ForEach(timezones) { timezone in
                    let active = selectedTimezone ?? hoveredTimezone
                    let isActive = active == nil || active == timezone.timezone
                    
                    SectorMark(
                        angle: .value("Count", timezone.count),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(color(for: timezone.timezone))
                    .opacity(isActive ? 1.0 : 0.3)
                    .cornerRadius(4)
                }
            }
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if let selected = selectedTimezoneStat {
                        VStack(spacing: 4) {
                            Text(selected.timezone)
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("\(selected.count) usuários")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.1f", percentage(for: selected)))%")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(color(for: selected.timezone))
                        }
                        .frame(width: geometry.size.width * 0.4, height: geometry.size.height * 0.4)
                    } else {
                        VStack(spacing: 4) {
                            Text("Total")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("\(totalCount) usuários")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(timezones.count) timezones")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: geometry.size.width * 0.4, height: geometry.size.height * 0.4)
                    }
                }
            }
            .frame(height: 300)
            
            // Legend
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(timezones.prefix(10))) { timezone in
                    Button(action: {
                        selectedTimezone = selectedTimezone == timezone.timezone ? nil : timezone.timezone
                    }) {
                        HStack {
                            Circle()
                                .fill(color(for: timezone.timezone))
                                .frame(width: 12, height: 12)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(timezone.timezone)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                if !regionDescription(for: timezone.timezone).isEmpty {
                                    Text(regionDescription(for: timezone.timezone))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Text("\(timezone.count)")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                Text("(\(String(format: "%.1f", percentage(for: timezone)))%)")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(backgroundColor(for: timezone.timezone))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .onHover { isHovering in
                        hoveredTimezone = isHovering ? timezone.timezone : nil
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(platterColor)
        .cornerRadius(12)
        .padding(.horizontal)
        .onAppear {
            print("🔍 [DeviceAnalyticsSection] Timezones pie chart appeared (total: \(totalCount))")
        }
    }
    
    private func backgroundColor(for timezone: String) -> Color {
        let active = selectedTimezone ?? hoveredTimezone
        return active == timezone ? color(for: timezone).opacity(0.15) : Color.clear
    }
    
    private func regionDescription(for timezone: String) -> String {
        let tz = timezone.uppercased()
        
        // GMT offsets (e.g., GMT+1, GMT-5)
        if tz.hasPrefix("GMT") {
            let offsetString = tz.replacingOccurrences(of: "GMT", with: "").trimmingCharacters(in: .whitespaces)
            if offsetString.isEmpty {
                // Just "GMT" without offset
                return "Reino Unido/Irlanda"
            } else if let offset = Int(offsetString) {
                switch offset {
                case -8: return "Pacífico (EUA/Canadá)"
                case -6: return "América Central"
                case -5: return "América do Norte (EST)"
                case -3: return "América do Sul"
                case 0: return "Reino Unido/Irlanda"
                case 1: return "Europa Central"
                case 8: return "Ásia (China/Singapura)"
                default:
                    if offset < 0 {
                        return "Américas"
                    } else if offset > 0 && offset <= 3 {
                        return "Europa/África"
                    } else {
                        return "Ásia/Oceania"
                    }
                }
            }
        }
        
        // Common timezone abbreviations
        switch tz {
        case "EST", "EDT": return "América do Norte (Leste)"
        case "PST", "PDT": return "América do Norte (Pacífico)"
        case "CST", "CDT": return "América do Norte (Central)"
        case "MST", "MDT": return "América do Norte (Montanha)"
        case "AMT": return "Amazônia (Brasil)"
        case "BRT": return "Brasil"
        case "CET", "CEST": return "Europa Central"
        case "WET", "WEST": return "Europa Ocidental"
        case "EET", "EEST": return "Europa Oriental"
        case "JST": return "Japão"
        case "AEST", "AEDT": return "Austrália (Leste)"
        case "AWST": return "Austrália (Oeste)"
        case "IST": return "Índia"
        case "KST": return "Coreia"
        default:
            // Try to infer from common patterns
            if tz.contains("EUROPE") || tz.contains("PARIS") || tz.contains("BERLIN") {
                return "Europa"
            } else if tz.contains("AMERICA") || tz.contains("NEW_YORK") || tz.contains("LOS_ANGELES") {
                return "Américas"
            } else if tz.contains("ASIA") || tz.contains("TOKYO") || tz.contains("BEIJING") {
                return "Ásia"
            } else {
                return ""
            }
        }
    }
}

// MARK: - Timezone Row

struct TimezoneRow: View {
    let timezone: TimezoneStat
    let totalCount: Int
    
    var percentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(timezone.count) / Double(totalCount) * 100
    }
    
    var regionDescription: String {
        let tz = timezone.timezone.uppercased()
        
        // GMT offsets (e.g., GMT+1, GMT-5)
        if tz.hasPrefix("GMT") {
            let offsetString = tz.replacingOccurrences(of: "GMT", with: "").trimmingCharacters(in: .whitespaces)
            if offsetString.isEmpty {
                // Just "GMT" without offset
                return "Reino Unido/Irlanda"
            } else if let offset = Int(offsetString) {
                switch offset {
                case -8: return "Pacífico (EUA/Canadá)"
                case -6: return "América Central"
                case -5: return "América do Norte (EST)"
                case -3: return "América do Sul"
                case 0: return "Reino Unido/Irlanda"
                case 1: return "Europa Central"
                case 8: return "Ásia (China/Singapura)"
                default:
                    if offset < 0 {
                        return "Américas"
                    } else if offset > 0 && offset <= 3 {
                        return "Europa/África"
                    } else {
                        return "Ásia/Oceania"
                    }
                }
            }
        }
        
        // Common timezone abbreviations
        switch tz {
        case "EST", "EDT": return "América do Norte (Leste)"
        case "PST", "PDT": return "América do Norte (Pacífico)"
        case "CST", "CDT": return "América do Norte (Central)"
        case "MST", "MDT": return "América do Norte (Montanha)"
        case "AMT": return "Amazônia (Brasil)"
        case "CET", "CEST": return "Europa Central"
        case "WET", "WEST": return "Europa Ocidental"
        case "EET", "EEST": return "Europa Oriental"
        case "JST": return "Japão"
        case "AEST", "AEDT": return "Austrália (Leste)"
        case "AWST": return "Austrália (Oeste)"
        case "IST": return "Índia"
        case "KST": return "Coreia"
        default:
            // Try to infer from common patterns
            if tz.contains("EUROPE") || tz.contains("PARIS") || tz.contains("BERLIN") {
                return "Europa"
            } else if tz.contains("AMERICA") || tz.contains("NEW_YORK") || tz.contains("LOS_ANGELES") {
                return "Américas"
            } else if tz.contains("ASIA") || tz.contains("TOKYO") || tz.contains("BEIJING") {
                return "Ásia"
            } else {
                return ""
            }
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: "globe")
                .foregroundColor(.orange)
                .font(.title3)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(timezone.timezone)
                    .font(.body)
                
                if !regionDescription.isEmpty {
                    Text(regionDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("\(timezone.count)")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text("(\(String(format: "%.1f", percentage))%)")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(platterColor)
        .cornerRadius(8)
    }
}

// MARK: - Navigation Analytics Section

struct NavigationAnalyticsSection: View {
    let analytics: NavigationAnalyticsResponse
    
    // Calculate adjusted total views excluding didViewSpecificReaction for percentage calculations
    var adjustedTotalViews: Int {
        let specificReactionCount = analytics.topScreens.first { $0.screenName == "didViewSpecificReaction" }?.viewCount ?? 0
        return analytics.totalViews - specificReactionCount
    }
    
    // Screens for bar chart (excluding didViewSpecificReaction)
    var screensForChart: [ScreenViewStat] {
        analytics.topScreens.filter { $0.screenName != "didViewSpecificReaction" }
    }
    
    // didViewSpecificReaction entry (if exists)
    var specificReactionScreen: ScreenViewStat? {
        analytics.topScreens.first { $0.screenName == "didViewSpecificReaction" }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section Header
            HStack {
                Image(systemName: "map")
                    .foregroundColor(.indigo)
                    .font(.title2)
                Text("Navegação no App")
                    .font(.headline)
            }
            .padding(.horizontal)
            
            // Bar Chart
            if !screensForChart.isEmpty {
                NavigationBarChart(
                    screens: screensForChart,
                    adjustedTotalViews: adjustedTotalViews
                )
            }
            
            // Show didViewSpecificReaction separately (without percentage)
            if let specificReaction = specificReactionScreen {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.indigo)
                            .font(.title3)
                        Text("Nota")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal)
                    
                    ScreenViewRow(
                        screen: specificReaction,
                        totalViews: analytics.totalViews,
                        adjustedTotalViews: adjustedTotalViews
                    )
                    .padding(.horizontal)
                }
                .padding()
                .background(platterColor)
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Navigation Bar Chart

struct NavigationBarChart: View {
    let screens: [ScreenViewStat]
    let adjustedTotalViews: Int
    @State private var selectedScreen: String?
    
    private func percentage(for screen: ScreenViewStat) -> Double {
        guard adjustedTotalViews > 0 else { return 0 }
        return Double(screen.viewCount) / Double(adjustedTotalViews) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.indigo)
                    .font(.title3)
                Text("Telas Mais Acessadas")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                
                Text("\(adjustedTotalViews) visualizações")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            Chart {
                ForEach(Array(screens.prefix(15))) { screen in
                    BarMark(
                        x: .value("Views", screen.viewCount),
                        y: .value("Screen", screen.displayName)
                    )
                    .foregroundStyle(.indigo.gradient)
                    .cornerRadius(4)
                    .annotation(position: .trailing, alignment: .leading, spacing: 4) {
                        Text("\(screen.viewCount)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel()
                }
            }
            .frame(height: CGFloat(min(screens.count, 15) * 32 + 40))
        }
        .padding()
        .background(platterColor)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Screen View Row

struct ScreenViewRow: View {
    let screen: ScreenViewStat
    let totalViews: Int
    let adjustedTotalViews: Int
    
    // Show no percentage for didViewSpecificReaction
    var shouldShowPercentage: Bool {
        screen.screenName != "didViewSpecificReaction"
    }
    
    var percentage: Double {
        guard shouldShowPercentage, adjustedTotalViews > 0 else { return 0 }
        return Double(screen.viewCount) / Double(adjustedTotalViews) * 100
    }
    
    var body: some View {
        HStack {
            Image(systemName: screen.iconName)
                .foregroundColor(.indigo)
                .font(.title3)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(screen.displayName)
                    .font(.body)
                    .lineLimit(2)
            }
            
            Spacer()
            
            HStack(spacing: 4) {
                Text("\(screen.viewCount)")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                if shouldShowPercentage {
                    Text("(\(String(format: "%.1f", percentage))%)")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(platterColor)
        .cornerRadius(8)
    }
}

// MARK: - Section Loading View

struct SectionLoadingView: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            HStack {
                Spacer()
                ProgressView()
                    .scaleEffect(1.2)
                Spacer()
            }
            .frame(height: 100)
        }
        .padding()
        .background(platterColor)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Section Error View

struct SectionErrorView: View {
    let title: String
    let icon: String
    let color: Color
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title)
                    .foregroundColor(.orange)
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Button("Tentar Novamente") {
                    retryAction()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .padding()
        .background(platterColor)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Stat Card Loading View

struct StatCardLoading: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)
                .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                ProgressView()
            }
            
            Spacer()
        }
        .padding()
        .background(platterColor)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Stat Card Error View

struct StatCardError: View {
    let title: String
    let icon: String
    let color: Color
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color.opacity(0.5))
                .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Erro")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Retry") {
                        retryAction()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(platterColor)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        AnalyticsView()
    }
}

