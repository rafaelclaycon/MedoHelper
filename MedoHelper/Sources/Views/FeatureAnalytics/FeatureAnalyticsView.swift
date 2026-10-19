//
//  FeatureAnalyticsView.swift
//  MedoHelper
//
//  Created by Claude on 04/10/26.
//

import SwiftUI

/// Statistics for specific app features, one section per feature: the election Live
/// Activity ("Apuração ao Vivo"), the games, episodes, Share Clip and chapters.
struct FeatureAnalyticsView: View {

    @State private var viewModel = ViewModel()
    @State private var containerWidth: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Picker("Período", selection: $viewModel.period) {
                        ForEach(Period.allCases) { period in
                            Text(period.label).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .fixedSize()

                    Spacer()

                    if let lastUpdated = viewModel.lastUpdated {
                        Text("Última atualização: \(lastUpdated.formatted(date: .omitted, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(alignment: .top, spacing: Feature.columnSpacing) {
                    ForEach(Feature.columns(count: Feature.columnCount(for: containerWidth)), id: \.first) { column in
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(column) { feature in
                                if feature != column.first {
                                    Divider()
                                }
                                section(for: feature)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }
                .onGeometryChange(for: CGFloat.self) { proxy in
                    proxy.size.width
                } action: { width in
                    containerWidth = width
                }
            }
            .padding()
        }
        .navigationTitle("Estatísticas por Funcionalidade")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel.onRetry() }
                    Task { await viewModel.onRetryGames() }
                    Task { await viewModel.onRetryEpisodeFeatures() }
                } label: {
                    Label("Recarregar", systemImage: "arrow.clockwise")
                }
                .help("Recarregar do servidor")
            }
        }
        .task(id: viewModel.period) {
            await viewModel.refreshPeriodically()
        }
        .task(id: viewModel.gamesWindow) {
            await viewModel.refreshGamesPeriodically()
        }
        .task {
            await viewModel.refreshEpisodeFeaturesPeriodically()
        }
    }

    @ViewBuilder
    private func section(for feature: Feature) -> some View {
        switch feature {
        case .election:
            ElectionLiveSection(state: viewModel.electionLive, series: viewModel.electionSeries) {
                Task { await viewModel.onRetry() }
            }
        case .games:
            GamesSection(state: viewModel.games, window: $viewModel.gamesWindow) {
                Task { await viewModel.onRetryGames() }
            }
        case .episodes:
            EpisodesSection(state: viewModel.episodes, transcripts: viewModel.transcripts) {
                Task { await viewModel.onRetryEpisodeFeatures() }
            }
        case .shareClip:
            ShareClipSection(state: viewModel.shareClip) {
                Task { await viewModel.onRetryEpisodeFeatures() }
            }
        case .chapters:
            ChaptersSection(state: viewModel.chapters) {
                Task { await viewModel.onRetryEpisodeFeatures() }
            }
        }
    }
}

#Preview {
    FeatureAnalyticsView()
        .frame(width: 1000, height: 800)
}
