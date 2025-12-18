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
    
    // Individual loading states for each section
    @State private var activeUsers: LoadingState<Int> = .loading
    @State private var dailyUserCounts: LoadingState<[DailyUserCount]> = .loading
    @State private var topSharedSounds: LoadingState<[SharedSoundRank]> = .loading
    @State private var deviceAnalytics: LoadingState<DeviceAnalyticsResponse> = .loading
    @State private var navigationAnalytics: LoadingState<NavigationAnalyticsResponse> = .loading
    @State private var retro2025: LoadingState<Retro2025DashboardResponse> = .loading
    
    @State private var lastUpdated: Date?
    
    private let repository: AnalyticsRepositoryProtocol
    private let timer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()
    
    private var todayString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: Date())
    }

    init(repository: AnalyticsRepositoryProtocol = AnalyticsRepository()) {
        self.repository = repository
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
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
                
                // Side-by-side layout
                HStack(alignment: .top, spacing: 20) {
                    // Regular Analytics Column (Left)
                    VStack(alignment: .leading, spacing: 20) {
                        // Active Users Card
                        activeUsersSection
                        
                        // 30-Day User Trend Chart
                        dailyUserCountsSection
                        
                        // Top Shared Sounds
                        topSharedSoundsSection
                        
                        // Device & System Analytics
                        deviceAnalyticsSection
                        
                        // Navigation Analytics
                        navigationAnalyticsSection
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Retro2025 Section Column (Right)
                    retro2025Section
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
            StatCardLoading(title: "Usuários Ativos Hoje", icon: "person.2.fill", color: .blue)
        case .loaded(let count):
            StatCard(title: "Usuários Ativos Hoje", value: "\(count)", icon: "person.2.fill", color: .blue)
        case .error(let message):
            StatCardError(title: "Usuários Ativos Hoje", icon: "person.2.fill", color: .blue, message: message) {
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
    private var topSharedSoundsSection: some View {
        switch topSharedSounds {
        case .loading:
            SectionLoadingView(title: "Sons Mais Compartilhados", icon: "arrow.up.message.fill", color: .orange)
        case .loaded(let sounds):
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "arrow.up.message.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                    Text("Sons Mais Compartilhados")
                        .font(.headline)
                }
                .padding(.horizontal)
                
                VStack(spacing: 8) {
                    ForEach(sounds) { sound in
                        SharedSoundRow(sound: sound)
                    }
                }
            }
            .padding()
            .background(platterColor)
            .cornerRadius(12)
            .padding(.horizontal)
        case .error(let message):
            SectionErrorView(
                title: "Sons Mais Compartilhados",
                icon: "arrow.up.message.fill",
                color: .orange,
                message: message
            ) {
                fetchTopSharedSounds()
            }
        }
    }
    
    @ViewBuilder
    private var deviceAnalyticsSection: some View {
        switch deviceAnalytics {
        case .loading:
            SectionLoadingView(title: "Dispositivos e Sistema", icon: "iphone", color: .blue)
        case .loaded(let analytics):
            DeviceAnalyticsSection(analytics: analytics)
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
    
    @ViewBuilder
    private var retro2025Section: some View {
        switch retro2025 {
        case .loading:
            VStack(spacing: 20) {
                SectionLoadingView(title: "Retro2025 - Dezembro 2025", icon: "calendar.badge.clock", color: .purple)
            }
        case .loaded(let dashboard):
            Retro2025Section(dashboard: dashboard)
        case .error(let message):
            SectionErrorView(
                title: "Retro2025 - Dezembro 2025",
                icon: "calendar.badge.clock",
                color: .purple,
                message: message
            ) {
                fetchRetro2025()
            }
        }
    }
    
    // MARK: - Fetch Methods
    
    private func fetchAllSections() {
        lastUpdated = Date()
        fetchActiveUsers()
        fetchDailyUserCounts()
        fetchTopSharedSounds()
        fetchDeviceAnalytics()
        fetchNavigationAnalytics()
        fetchRetro2025()
    }
    
    private func fetchActiveUsers() {
        Task {
            activeUsers = .loading
            do {
                let count = try await repository.fetchActiveUsers(date: todayString)
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
    
    private func fetchTopSharedSounds() {
        Task {
            topSharedSounds = .loading
            do {
                let sounds = try await repository.fetchTopSharedSounds(date: todayString)
                await MainActor.run {
                    topSharedSounds = .loaded(sounds)
                }
            } catch {
                await MainActor.run {
                    topSharedSounds = .error(error.localizedDescription)
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
    
    private func fetchRetro2025() {
        Task {
            retro2025 = .loading
            do {
                let dashboard = try await repository.fetchRetro2025Dashboard(startDate: "2025-12-01", endDate: "2025-12-31")
                await MainActor.run {
                    retro2025 = .loaded(dashboard)
                }
            } catch {
                await MainActor.run {
                    retro2025 = .error(error.localizedDescription)
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
                Text("Retro2025 - Dezembro 2025")
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

// MARK: - Device Analytics Section

struct DeviceAnalyticsSection: View {
    let analytics: DeviceAnalyticsResponse
    
    init(analytics: DeviceAnalyticsResponse) {
        self.analytics = analytics
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
            if !analytics.topIOSVersions.isEmpty {
                let totalIOSVersions = analytics.topIOSVersions.reduce(0) { $0 + $1.count }
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
                        ForEach(analytics.topIOSVersions) { version in
                            IOSVersionRow(version: version, totalCount: totalIOSVersions)
                        }
                    }
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
                        ForEach(Array(analytics.topDeviceModels.prefix(5))) { model in
                            DeviceModelRow(model: model, totalCount: totalDeviceModels)
                        }
                    }
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
    let totalCount: Int
    
    var percentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(model.count) / Double(totalCount) * 100
    }
    
    var body: some View {
        HStack {
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
    
    // Screens for pie chart (excluding didViewSpecificReaction)
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
            
            // Pie Chart
            if !screensForChart.isEmpty {
                NavigationPieChart(
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

// MARK: - Navigation Pie Chart

struct NavigationPieChart: View {
    let screens: [ScreenViewStat]
    let adjustedTotalViews: Int
    @State private var selectedScreen: String?
    @State private var hoveredScreen: String?
    
    private let colors: [Color] = [
        .indigo, .blue, .purple, .pink, .orange,
        .green, .teal, .cyan, .mint, .yellow,
        .red, .brown, .gray
    ]
    
    private func color(for screenName: String) -> Color {
        let index = screens.firstIndex(where: { $0.screenName == screenName }) ?? 0
        return colors[index % colors.count]
    }
    
    private func percentage(for screen: ScreenViewStat) -> Double {
        guard adjustedTotalViews > 0 else { return 0 }
        return Double(screen.viewCount) / Double(adjustedTotalViews) * 100
    }
    
    var selectedScreenStat: ScreenViewStat? {
        let active = selectedScreen ?? hoveredScreen
        guard let active = active else { return nil }
        return screens.first { $0.screenName == active }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "rectangle.stack")
                    .foregroundColor(.indigo)
                    .font(.title3)
                Text("Telas Mais Acessadas")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                
                // Show selected screen info
                if let selected = selectedScreenStat {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(selected.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("\(selected.viewCount) (\(String(format: "%.1f", percentage(for: selected)))%)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            
            Chart {
                ForEach(screens) { screen in
                    let active = selectedScreen ?? hoveredScreen
                    let isActive = active == nil || active == screen.screenName
                    
                    SectorMark(
                        angle: .value("Count", screen.viewCount),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(color(for: screen.screenName))
                    .opacity(isActive ? 1.0 : 0.3)
                    .cornerRadius(4)
                }
            }
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if let selected = selectedScreenStat {
                        VStack(spacing: 4) {
                            Text(selected.displayName)
                                .font(.headline)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            Text("\(selected.viewCount) visualizações")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(String(format: "%.1f", percentage(for: selected)))%")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(color(for: selected.screenName))
                        }
                        .frame(width: geometry.size.width * 0.4, height: geometry.size.height * 0.4)
                    } else {
                        VStack(spacing: 4) {
                            Text("Total")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("\(adjustedTotalViews) visualizações")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("\(screens.count) telas")
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
                ForEach(Array(screens.prefix(15))) { screen in
                    Button(action: {
                        selectedScreen = selectedScreen == screen.screenName ? nil : screen.screenName
                    }) {
                        HStack {
                            Circle()
                                .fill(color(for: screen.screenName))
                                .frame(width: 12, height: 12)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(screen.displayName)
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Text("\(screen.viewCount)")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                Text("(\(String(format: "%.1f", percentage(for: screen)))%)")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(backgroundColor(for: screen.screenName))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .onHover { isHovering in
                        hoveredScreen = isHovering ? screen.screenName : nil
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(platterColor)
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func backgroundColor(for screenName: String) -> Color {
        let active = selectedScreen ?? hoveredScreen
        return active == screenName ? color(for: screenName).opacity(0.15) : Color.clear
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

