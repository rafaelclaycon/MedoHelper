//
//  FeatureAnalyticsView.swift
//  MedoHelper
//
//  Created by Claude on 04/10/26.
//

import SwiftUI

/// Statistics for specific app features, one section per feature. Starts with the
/// election Live Activity ("Apuração ao Vivo").
struct FeatureAnalyticsView: View {

    @State private var viewModel = ViewModel()

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

                ElectionLiveSection(state: viewModel.electionLive, series: viewModel.electionSeries) {
                    Task { await viewModel.onRetry() }
                }
            }
            .padding()
        }
        .navigationTitle("Estatísticas por Funcionalidade")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await viewModel.onRetry() }
                } label: {
                    Label("Recarregar", systemImage: "arrow.clockwise")
                }
                .help("Recarregar do servidor")
            }
        }
        .task(id: viewModel.period) {
            await viewModel.refreshPeriodically()
        }
    }
}

#Preview {
    FeatureAnalyticsView()
        .frame(width: 1000, height: 800)
}
