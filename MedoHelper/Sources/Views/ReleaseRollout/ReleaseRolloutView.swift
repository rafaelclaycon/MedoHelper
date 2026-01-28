//
//  ReleaseRolloutView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 28/01/26.
//

import SwiftUI
import Charts

private let platterColor = Color.gray.opacity(0.3)

// MARK: - Version Color Provider

/// Generates unique colors for versions using a curated palette with golden ratio fallback
struct VersionColorProvider {
    
    // Curated palette of distinct, visually appealing colors
    private static let curatedColors: [Color] = [
        Color(hue: 0.35, saturation: 0.7, brightness: 0.8),  // Green
        Color(hue: 0.58, saturation: 0.7, brightness: 0.8),  // Blue
        Color(hue: 0.08, saturation: 0.8, brightness: 0.9),  // Orange
        Color(hue: 0.75, saturation: 0.6, brightness: 0.7),  // Purple
        Color(hue: 0.95, saturation: 0.6, brightness: 0.85), // Pink
        Color(hue: 0.0, saturation: 0.7, brightness: 0.8),   // Red
        Color(hue: 0.5, saturation: 0.6, brightness: 0.7),   // Teal
        Color(hue: 0.65, saturation: 0.5, brightness: 0.6),  // Indigo
    ]
    
    private static let goldenRatio = 0.618033988749895
    
    /// Returns a unique color for the given index
    static func color(for index: Int) -> Color {
        if index < curatedColors.count {
            return curatedColors[index]
        } else {
            // Generate additional colors using golden ratio for good distribution
            var hue = Double(index) * goldenRatio
            hue = hue.truncatingRemainder(dividingBy: 1.0)
            // Vary saturation and brightness slightly for more distinction
            let saturation = 0.5 + (Double(index % 3) * 0.15)
            let brightness = 0.6 + (Double(index % 4) * 0.1)
            return Color(hue: hue, saturation: saturation, brightness: brightness)
        }
    }
    
    /// Creates a color mapping dictionary for a list of versions
    static func colorMap(for versions: [String]) -> [String: Color] {
        var map: [String: Color] = [:]
        for (index, version) in versions.enumerated() {
            map[version] = color(for: index)
        }
        return map
    }
}

struct ReleaseRolloutView: View {
    
    @State private var selectedDate: Date = Date()
    @State private var hourlyData: LoadingState<HourlyVersionResponse> = .loading
    @State private var dailyAdoption: LoadingState<[DailyVersionData]> = .loading
    @State private var distribution: LoadingState<VersionDistributionResponse> = .loading
    
    @State private var lastUpdated: Date?
    
    private let repository: AnalyticsRepositoryProtocol
    private let timer = Timer.publish(every: 120, on: .main, in: .common).autoconnect() // 2 minutes
    
    init(repository: AnalyticsRepositoryProtocol = AnalyticsRepository()) {
        self.repository = repository
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with date picker and last updated
                headerSection
                
                // Main content in two columns
                HStack(alignment: .top, spacing: 20) {
                    // Left column
                    VStack(spacing: 20) {
                        // Version distribution stat cards
                        distributionCardsSection
                        
                        // Hourly adoption chart
                        hourlyChartSection
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Right column
                    VStack(spacing: 20) {
                        // Version pie chart
                        versionPieChartSection
                        
                        // 7-day trend
                        dailyTrendSection
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .navigationTitle("Release Rollout")
        .onAppear {
            fetchAllData()
        }
        .onReceive(timer) { _ in
            fetchAllData()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            DatePicker(
                "Data",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .onChange(of: selectedDate) { _, _ in
                fetchHourlyData()
            }
            
            Spacer()
            
            if let lastUpdated = lastUpdated {
                Text("Última atualização: \(formattedTime(lastUpdated))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button(action: fetchAllData) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Distribution Cards Section
    
    @ViewBuilder
    private var distributionCardsSection: some View {
        switch distribution {
        case .loading:
            HStack(spacing: 16) {
                StatCardLoading(title: "Versão Mais Recente", icon: "arrow.up.circle.fill", color: .green)
                StatCardLoading(title: "Total de Usuários Hoje", icon: "person.2.fill", color: .blue)
            }
        case .loaded(let response):
            let latestVersion = response.versions.first
            HStack(spacing: 16) {
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
            HStack(spacing: 16) {
                StatCardError(title: "Versão Mais Recente", icon: "arrow.up.circle.fill", color: .green, message: message) {
                    fetchDistribution()
                }
                StatCardError(title: "Total de Usuários Hoje", icon: "person.2.fill", color: .blue, message: message) {
                    fetchDistribution()
                }
            }
        }
    }
    
    // MARK: - Hourly Chart Section
    
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
    
    // MARK: - Version Pie Chart Section
    
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
    
    // MARK: - Daily Trend Section
    
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
    
    // MARK: - Fetch Methods
    
    private func fetchAllData() {
        lastUpdated = Date()
        fetchHourlyData()
        fetchDistribution()
        fetchDailyAdoption()
    }
    
    private func fetchHourlyData() {
        Task {
            hourlyData = .loading
            do {
                let dateString = formatDate(selectedDate)
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
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Hourly Adoption Chart

struct HourlyAdoptionChart: View {
    let response: HourlyVersionResponse
    
    // Get all unique versions sorted by total users (from dayTotals)
    private var allVersions: [String] {
        response.dayTotals.map { $0.appVersion }
    }
    
    // Color mapping for consistent colors
    private var colorMap: [String: Color] {
        VersionColorProvider.colorMap(for: allVersions)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                Text("Adoção por Hora - \(response.date)")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            if response.hours.isEmpty || response.dayTotals.isEmpty {
                Text("Sem dados para este dia")
                    .foregroundColor(.secondary)
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(response.hours) { slot in
                    ForEach(slot.versions, id: \.appVersion) { versionStat in
                        BarMark(
                            x: .value("Hora", slot.hour),
                            y: .value("Usuários", versionStat.uniqueUsers)
                        )
                        .foregroundStyle(by: .value("Versão", versionStat.appVersion))
                    }
                }
                .chartForegroundStyleScale(
                    domain: allVersions,
                    range: allVersions.map { colorMap[$0] ?? .gray }
                )
                .chartXAxis {
                    AxisMarks(values: .stride(by: 2)) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let hour = value.as(Int.self) {
                                Text(String(format: "%02d:00", hour))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 250)
            }
            
            // Legend from dayTotals
            if !response.dayTotals.isEmpty {
                HStack(spacing: 12) {
                    ForEach(Array(response.dayTotals.prefix(6).enumerated()), id: \.element.appVersion) { index, version in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(VersionColorProvider.color(for: index))
                                .frame(width: 10, height: 10)
                            Text(version.appVersion)
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(platterColor)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Version Pie Chart

struct VersionPieChart: View {
    let versions: [VersionStat]
    let totalUsers: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundColor(.purple)
                    .font(.title2)
                Text("Distribuição de Versões")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            if versions.isEmpty {
                Text("Sem dados de versões")
                    .foregroundColor(.secondary)
                    .frame(height: 250)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(Array(versions.enumerated()), id: \.element.appVersion) { index, version in
                    SectorMark(
                        angle: .value("Usuários", version.uniqueUsers),
                        innerRadius: .ratio(0.5),
                        angularInset: 2
                    )
                    .foregroundStyle(VersionColorProvider.color(for: index))
                    .cornerRadius(4)
                }
                .chartBackground { _ in
                    VStack(spacing: 4) {
                        Text("Total")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("\(totalUsers)")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("\(versions.count) versões")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 250)
            }
            
            // Legend
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(versions.prefix(8).enumerated()), id: \.element.appVersion) { index, version in
                    HStack {
                        Circle()
                            .fill(VersionColorProvider.color(for: index))
                            .frame(width: 12, height: 12)
                        
                        Text(version.appVersion)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(version.uniqueUsers)")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        if let pct = version.percentage {
                            Text(String(format: "(%.1f%%)", pct))
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(platterColor)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Daily Version Trend Chart

struct DailyVersionTrendChart: View {
    let dailyData: [DailyVersionData]
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private func dateValue(_ dateString: String) -> Date {
        Self.dateFormatter.date(from: dateString) ?? Date()
    }
    
    // Get top versions from the most recent day, sorted by users
    private var topVersions: [String] {
        guard let lastDay = dailyData.last else { return [] }
        return lastDay.versions
            .sorted { $0.uniqueUsers > $1.uniqueUsers }
            .prefix(5)
            .map { $0.appVersion }
    }
    
    // Color mapping for consistent colors
    private var colorMap: [String: Color] {
        VersionColorProvider.colorMap(for: topVersions)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text("Tendência - Últimos 7 Dias")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            if dailyData.isEmpty {
                Text("Sem dados de tendência")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else {
                // Only show top 5 versions to avoid chart complexity
                Chart {
                    ForEach(dailyData, id: \.date) { day in
                        ForEach(day.versions.filter { topVersions.contains($0.appVersion) }, id: \.appVersion) { version in
                            LineMark(
                                x: .value("Data", dateValue(day.date), unit: .day),
                                y: .value("Usuários", version.uniqueUsers)
                            )
                            .foregroundStyle(by: .value("Versão", version.appVersion))
                            .interpolationMethod(.catmullRom)
                            
                            PointMark(
                                x: .value("Data", dateValue(day.date), unit: .day),
                                y: .value("Usuários", version.uniqueUsers)
                            )
                            .foregroundStyle(by: .value("Versão", version.appVersion))
                            .symbolSize(30)
                        }
                    }
                }
                .chartForegroundStyleScale(
                    domain: topVersions,
                    range: topVersions.map { colorMap[$0] ?? .gray }
                )
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day(), centered: true)
                    }
                }
                .frame(height: 200)
            }
            
            // Legend
            if !topVersions.isEmpty {
                HStack(spacing: 12) {
                    ForEach(Array(topVersions.enumerated()), id: \.element) { index, version in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(VersionColorProvider.color(for: index))
                                .frame(width: 10, height: 10)
                            Text(version)
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(platterColor)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        ReleaseRolloutView()
    }
}
