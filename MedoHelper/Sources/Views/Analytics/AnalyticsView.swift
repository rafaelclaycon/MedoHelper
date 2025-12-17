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
    
    @State private var analytics: Analytics?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var lastUpdated: Date?
    
    private let repository: AnalyticsRepositoryProtocol
    private let timer = Timer.publish(every: 300, on: .main, in: .common).autoconnect()

    init(repository: AnalyticsRepositoryProtocol = AnalyticsRepository()) {
        self.repository = repository
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading && analytics == nil {
                    LoadingView()
                } else if let analytics = analytics {
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
                            StatCard(
                                title: "Usuários Ativos Hoje",
                                value: "\(analytics.activeUsers)",
                                icon: "person.2.fill",
                                color: .blue
                            )
                            
                            // 30-Day User Trend Chart
                            if let dailyUserCounts = analytics.dailyUserCounts, !dailyUserCounts.isEmpty {
                                DailyUserCountChart(dailyUserCounts: dailyUserCounts)
                            }
                            
                            // Top Shared Sounds
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
                                    ForEach(analytics.topSharedSounds) { sound in
                                        SharedSoundRow(sound: sound)
                                    }
                                }
                            }
                            .padding()
                            .background(platterColor)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Retro2025 Section Column (Right)
                        if let retro2025 = analytics.retro2025 {
                            Retro2025Section(dashboard: retro2025)
                                .frame(maxWidth: .infinity)
                        }
                    }
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        Text("Erro ao carregar dados")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Tentar Novamente") {
                            fetchAnalytics()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
            .padding(.vertical)
            .padding(.horizontal)
        }
        .navigationTitle("Estatísticas do App")
        .onAppear {
            fetchAnalytics()
        }
        .onReceive(timer) { _ in
            fetchAnalytics()
        }
    }
    
    private func fetchAnalytics() {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                let fetchedAnalytics = try await repository.fetchAnalytics()
                await MainActor.run {
                    self.analytics = fetchedAnalytics
                    self.lastUpdated = Date()
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
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

#Preview {
    NavigationStack {
        AnalyticsView()
    }
}
