//
//  SoundRequestsView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 19/04/26.
//

import SwiftUI

struct SoundRequestsView: View {

    @StateObject private var viewModel = ViewModel()

    var body: some View {
        HSplitView {
            leftPane
                .frame(minWidth: 360, idealWidth: 440)

            TranscriptSearchPanel()
                .frame(minWidth: 360)
        }
        .navigationTitle("Pedidos")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    viewModel.onCreateRequestSelected()
                } label: {
                    Label("Novo Pedido", systemImage: "plus")
                }
                .help("Novo Pedido")

                Button {
                    Task { await viewModel.onReloadSelected() }
                } label: {
                    Label("Recarregar", systemImage: "arrow.clockwise")
                }
                .help("Recarregar")
            }
        }
        .sheet(isPresented: $viewModel.showingNewRequestSheet) {
            NewSoundRequestSheet(
                onConfirm: { title, requester, emailReceivedAt in
                    Task {
                        await viewModel.onConfirmCreate(
                            title: title,
                            requesterName: requester,
                            emailReceivedAt: emailReceivedAt
                        )
                    }
                },
                onCancel: {
                    viewModel.showingNewRequestSheet = false
                }
            )
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage)
        }
        .task {
            await viewModel.onViewAppear()
        }
    }

    // MARK: - Left Pane

    @ViewBuilder
    private var leftPane: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("Carregando Pedidos...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded(let requests):
            if requests.isEmpty {
                ContentUnavailableView {
                    Label("Nenhum Pedido", systemImage: "tray")
                } description: {
                    Text("Adicione um novo pedido recebido por e-mail usando o botão no canto superior.")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                requestsTable(requests)
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
                    Task { await viewModel.onReloadSelected() }
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func requestsTable(_ requests: [SoundRequest]) -> some View {
        Table(requests, selection: $viewModel.selectedRequestId) {
            TableColumn("Status") { request in
                StatusPill(status: request.status)
            }
            .width(min: 90, ideal: 100, max: 120)

            TableColumn("Título", value: \.title)

            TableColumn("Solicitante", value: \.requesterName)
                .width(min: 110, ideal: 140)

            TableColumn("E-mail Recebido") { request in
                Text(request.emailReceivedAt, format: .dateTime.day().month().year(.twoDigits))
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .width(min: 110, ideal: 130, max: 150)
        }
        .contextMenu(forSelectionType: SoundRequest.ID.self) { selection in
            if let id = selection.first,
               let request = requests.first(where: { $0.id == id }) {
                Button(toggleLabel(for: request.status)) {
                    Task { await viewModel.onToggleStatus(id: id) }
                }
                Divider()
                Button("Excluir", role: .destructive) {
                    Task { await viewModel.onRemoveSelected(id: id) }
                }
            }
        }
    }

    private func toggleLabel(for status: SoundRequestStatus) -> String {
        switch status {
        case .unfulfilled: return "Marcar como Atendido"
        case .fulfilled: return "Marcar como Pendente"
        }
    }
}

// MARK: - Status Pill

private struct StatusPill: View {

    let status: SoundRequestStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.systemImage)
                .font(.caption)
            Text(status.label)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .foregroundColor(foreground)
        .background(background)
        .clipShape(Capsule())
    }

    private var foreground: Color {
        switch status {
        case .unfulfilled: return .orange
        case .fulfilled: return .green
        }
    }

    private var background: Color {
        switch status {
        case .unfulfilled: return .orange.opacity(0.15)
        case .fulfilled: return .green.opacity(0.15)
        }
    }
}

#Preview {
    SoundRequestsView()
        .frame(width: 900, height: 600)
}
