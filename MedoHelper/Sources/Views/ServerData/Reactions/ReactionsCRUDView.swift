//
//  ReactionsCRUDView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 01/05/24.
//

import SwiftUI

struct ReactionsCRUDView: View {

    @StateObject private var viewModel = ViewModel(reactionRepository: ReactionRepository())

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    // MARK: - Environment

    @Environment(\.colorScheme) var colorScheme

    // MARK: - View Body

    var body: some View {
        VStack {
            if viewModel.isLoading {
                VerticalLoadingView(message: viewModel.loadingMessage.uppercased())
            } else {
                switch viewModel.state {
                case .loading:
                    VerticalLoadingView(message: viewModel.loadingMessage.uppercased())

                case .loaded(let data):
                    if data.reactions.isEmpty {
                        Text("Nenhuma Reação para exibir.")
                    } else {
                        ScrollView {
                            LazyVGrid(
                                columns: columns,
                                spacing: 12
                            ) {
                                ForEach(data.reactions) { reaction in
                                    ReactionItem(
                                        title: reaction.title,
                                        image: URL(string: reaction.image),
                                        itemHeight: 100,
                                        reduceTextSize: false
                                    )
                                    .onTapGesture {
                                        viewModel.onEditReactionSelected(reactionId: reaction.id)
                                    }
                                    .contextMenu {
                                        Button("Remover Reação") {
                                            viewModel.onRemoveReactionSelected(reactionId: reaction.id)
                                        }
                                    }
                                    .disabled(viewModel.isLoading)
                                }
                            }
                            .frame(width: 390)
                        }
                        .disabled(viewModel.isLoading)
                    }

                case .error(let errorString):
                    Text("Erro: \(errorString)")
                }
            }
        }
        .navigationTitle("Reações")
        .padding([.top, .leading, .trailing])
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    viewModel.onCreateNewReactionSelected()
                } label: {
                    Label("Nova Reação", systemImage: "plus")
                }
                .help("Nova Reação")

                Button {
                    Task {
                        await viewModel.onSendDataSelected()
                    }
                } label: {
                    Label("Enviar Dados", systemImage: "paperplane")
                }
                .help("Enviar Dados")
                .keyboardShortcut(.defaultAction)
                .disabled(viewModel.isSendDataButtonDisabled)
            }

            ToolbarItemGroup(placement: .secondaryAction) {
                Button {
                    Task {
                        await viewModel.onImportAndSendPreExistingReactionsSelected()
                    }
                } label: {
                    Label("Importar e Enviar", systemImage: "square.and.arrow.down")
                }
                .help("Importar e Enviar")
                .disabled(viewModel.reactions.count > 0)

                Button {
                    viewModel.onExportReactionsSelected()
                } label: {
                    Label("Exportar Reações", systemImage: "square.and.arrow.up")
                }
                .help("Exportar Reações")
                .disabled(viewModel.reactions.count == 0)
            }
        }
        .sheet(isPresented: $viewModel.isSending) {
            SendingProgressView(
                message: viewModel.modalMessage,
                currentAmount: viewModel.progressAmount,
                totalAmount: viewModel.totalAmount
            )
        }
        .sheet(item: $viewModel.reactionForEditing) { reaction in
            EditReactionView(
                reaction: reaction,
                sounds: viewModel.sounds,
                saveAction: { Task { await viewModel.onSaveReactionSelected() } },
                dismissSheet: { viewModel.reactionForEditing = nil },
                lastPosition: viewModel.lastReactionPosition
            )
            .frame(minWidth: 1024, minHeight: 700)
        }
        .alert(isPresented: $viewModel.showAlert) {
            switch viewModel.alertType {
            case .twoOptionsOneDelete:
                return Alert(
                    title: Text("Remover a Reação '\(viewModel.selectedReactionName)'?"),
                    message: Text("Essa ação não pode ser desfeita."),
                    primaryButton: .cancel(Text("Cancelar")),
                    secondaryButton: .default(
                        Text("Remover"),
                        action: {
                            Task {
                                await viewModel.onConfirmRemoveReactionSelected()
                            }
                        }
                    )
                )

            default:
                return Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .cancel(Text("OK"))
                )
            }
        }
        .onAppear {
            Task {
                await viewModel.onViewAppear()
            }
        }
    }
}

// MARK: - Subviews

extension ReactionsCRUDView {

    struct VerticalLoadingView: View {

        let message: String

        var body: some View {
            VStack {
                ProgressView()
                    .scaleEffect(0.7)

                Text(message)
                    .foregroundStyle(.gray)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ReactionsCRUDView()
}
