//
//  AnalyticsView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 23/05/23.
//

import SwiftUI

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
                    
                    // Active Users Card
                    StatCard(
                        title: "Usuários Ativos Hoje",
                        value: "\(analytics.activeUsers)",
                        icon: "person.2.fill",
                        color: .blue
                    )
                    
                    // Sessions Card
                    StatCard(
                        title: "Sessões Hoje",
                        value: "\(analytics.sessions)",
                        icon: "chart.bar.fill",
                        color: .green
                    )
                    
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

#Preview {
    NavigationStack {
        AnalyticsView()
    }
}
