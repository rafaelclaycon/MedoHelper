//
//  FolderResearchView.swift
//  MedoHelper
//
//  Created by Claude on 21/08/26.
//

import SwiftUI

/// Read-only research view for the "folder research" opt-in feature: browsable,
/// per-user snapshots of custom folders, their contents, device history, and how
/// each folder evolved over time.
struct FolderResearchView: View {

    @StateObject private var viewModel = ViewModel()

    var body: some View {
        content
            .navigationTitle("Pesquisa de Pastas")
            .searchable(text: $viewModel.searchText, prompt: "Buscar por nome de pasta ou conteúdo")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Picker("Ordenar", selection: $viewModel.sortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.label).tag(option)
                        }
                    }
                    .help("Ordenar usuários")

                    if !viewModel.availableDeviceModels.isEmpty {
                        Picker("Aparelho", selection: $viewModel.deviceModelFilter) {
                            ForEach(viewModel.availableDeviceModels, id: \.self) { model in
                                Text(model).tag(model)
                            }
                        }
                        .help("Filtrar por modelo de aparelho")
                    }

                    Button {
                        Task { await viewModel.onRetry() }
                    } label: {
                        Label("Recarregar", systemImage: "arrow.clockwise")
                    }
                    .help("Recarregar do servidor")
                }
            }
            .task {
                await viewModel.onViewAppear()
            }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Carregando Pesquisa de Pastas...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded(let response):
            if response.users.isEmpty {
                ContentUnavailableView {
                    Label("Nenhum Dado", systemImage: "folder")
                } description: {
                    Text("Nenhum usuário optou pela pesquisa de pastas ainda.")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                loadedContent(response)
            }

        case .error(let message):
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button("Tentar Novamente") {
                    Task { await viewModel.onRetry() }
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func loadedContent(_ response: FolderResearchAnalyticsResponse) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                summaryStrip(response)

                if viewModel.filteredUsers.isEmpty {
                    ContentUnavailableView.search
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else {
                    ForEach(viewModel.filteredUsers) { user in
                        FolderResearchUserRow(
                            user: user,
                            isExpanded: viewModel.expandedUserIDs.contains(user.id),
                            expandedFolderID: viewModel.expandedFolderID,
                            onToggleUser: { viewModel.toggleUserExpanded(user.id) },
                            onToggleFolder: { viewModel.toggleFolderExpanded($0) }
                        )
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Summary Strip

    @ViewBuilder
    private func summaryStrip(_ response: FolderResearchAnalyticsResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                StatCard(title: "Usuários", value: "\(response.totalUsers)", icon: "person.2", color: .purple)
                StatCard(title: "Pastas", value: "\(response.totalFolders)", icon: "folder", color: .orange)
                StatCard(title: "Conteúdos", value: "\(response.totalContentItems)", icon: "square.stack.3d.up", color: .teal)
            }

            FolderResearchChipsRow(title: "Nomes de pasta mais comuns", items: response.topFolderNames)
            FolderResearchChipsRow(title: "Emojis mais usados", items: response.topEmojis)
            FolderResearchChipsRow(title: "Cores mais usadas", items: response.topBackgroundColors, showsColorSwatch: true)
        }
    }
}

#Preview {
    FolderResearchView()
        .frame(width: 1000, height: 700)
}
