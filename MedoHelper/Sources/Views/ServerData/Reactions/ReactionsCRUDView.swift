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
            VStack {
                switch viewModel.state {
                case .loading:
                    Text(viewModel.loadingMessage)

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
                                }
                            }
                        }
                        .frame(width: 390)
                        .disabled(viewModel.isLoading)
                    }

                case .error(let errorString):
                    Text("Erro: \(errorString)")
                }


//                .contextMenu(forSelectionType: Sound.ID.self) { items in
//                    Section {
//                        Button("Editar Reação") {
//                            guard let selectedItemId = items.first else { return }
//                            viewModel.onEditReactionSelected(reactionId: selectedItemId)
//                        }
//                    }

//
//                HStack(spacing: 20) {
//                    HStack(spacing: 10) {

//
//                        Button {
//                            viewModel.onRemoveReactionSelected()
//                        } label: {
//                            Image(systemName: "minus")
//                        }
//                    }
//                    .disabled(viewModel.isLoading)
            }
            .navigationTitle("Reações")
            .padding([.top, .leading, .trailing])
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.onCreateNewReactionSelected()
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItemGroup(placement: .secondaryAction) {
                    HStack(spacing: 20) {
                        Spacer()

                        Button("Importar de Arquivo JSON") {
                            Task {
                                await viewModel.onImportAndSendPreExistingReactionsSelected()
                            }
                        }
                        .disabled(viewModel.reactions.count > 0)

                        Button("Exportar p/ JSON") {
                            viewModel.onExportReactionsSelected()
                        }
                        .disabled(viewModel.reactions.count == 0)

                        Spacer()
                            .frame(width: 40)

                        Button {
                            Task {
                                await viewModel.onSendDataSelected()
                            }
                        } label: {
                            Text("Enviar Dados")
                                .padding(.horizontal)
                        }
                        .keyboardShortcut(.defaultAction)
                        .disabled(viewModel.isSendDataButtonDisabled)
                    }
                    .padding(.all, 20)
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
                        title: Text("Deseja Remover Reação '\(viewModel.selectedReactionName)'?"),
                        message: Text("Tem certeza de que deseja remover essa Reação?"),
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
        .overlay {
            if viewModel.isLoading {
                LoadingView(message: viewModel.loadingMessage)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ReactionsCRUDView()
}
