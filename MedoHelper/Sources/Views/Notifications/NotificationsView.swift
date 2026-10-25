//
//  NotificationsView.swift
//  MedoHelper
//
//  Created by Claude on 25/10/26.
//

import SwiftUI

struct NotificationsView: View {

    @StateObject private var viewModel = ViewModel()

    var body: some View {
        ScrollView {
            HStack(alignment: .top, spacing: 40) {
                VStack(alignment: .leading, spacing: 24) {
                    textSection
                    sendButton

                    if let broadcast = viewModel.broadcast {
                        BroadcastProgressCard(
                            broadcast: broadcast,
                            isCancelling: viewModel.isCancelling,
                            onCancel: { Task { await viewModel.onCancelSelected() } }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .frame(minWidth: 380, maxWidth: 560)
                .animation(.smooth, value: viewModel.broadcast?.id)

                LockScreenPreview(
                    title: viewModel.title,
                    message: viewModel.body
                )
            }
            .padding(32)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Notificações")
        .confirmationDialog(
            confirmationTitle,
            isPresented: $viewModel.showSendConfirmation,
            titleVisibility: .visible
        ) {
            Button("Enviar") {
                Task { await viewModel.onSendConfirmed() }
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Não dá para desfazer. Dá para interromper no meio, mas quem já recebeu, recebeu.")
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.alertMessage)
        }
        .task {
            await viewModel.onViewAppear()
        }
        .onDisappear {
            viewModel.onViewDisappear()
        }
    }

    // MARK: - Sections

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mensagem")
                .font(.headline)
            Text("Vai para todos os aparelhos. Tocar na notificação só abre o app.")
                .font(.callout)
                .foregroundStyle(.secondary)

            TextField("Título", text: $viewModel.title)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .padding(.top, 4)

            TextField("Texto", text: $viewModel.body, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...8)
        }
        .disabled(viewModel.isSending)
    }

    private var sendButton: some View {
        Button {
            viewModel.onSendSelected()
        } label: {
            HStack(spacing: 10) {
                if viewModel.isStarting {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "paperplane.fill")
                }
                Text(sendButtonTitle)
            }
            .font(.title3.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.extraLarge)
        .disabled(!viewModel.canSend)
        .keyboardShortcut(.return, modifiers: .command)
    }

    // MARK: - Text

    private var sendButtonTitle: String {
        if viewModel.isSending {
            return "Enviando…"
        }
        guard let count = viewModel.audienceCount else {
            return "Enviar"
        }
        return "Enviar para \(count.formattedString) aparelhos"
    }

    private var confirmationTitle: String {
        let audience = viewModel.audienceCount.map { "\($0.formattedString) aparelhos" } ?? "todos os aparelhos"
        return "Mandar \"\(viewModel.title)\" para \(audience)?"
    }
}

#Preview {
    NotificationsView()
        .frame(width: 1100, height: 900)
}
