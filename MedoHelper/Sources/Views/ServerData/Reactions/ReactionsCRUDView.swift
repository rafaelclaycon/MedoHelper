//
//  ReactionsCRUDView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 01/05/24.
//

import SwiftUI

struct ReactionsCRUDView: View {

    @StateObject private var viewModel = ViewModel(reactionRepository: ReactionRepository())

    // MARK: - Environment

    @Environment(\.colorScheme) var colorScheme

    // MARK: - View Body

    var body: some View {
        VStack {
            VStack {
                Table(viewModel.searchResults, selection: $viewModel.selectedItem) {
                    TableColumn("Posição") { reaction in
                        Text("\(reaction.position)")
                    }
                    .width(min: 50, max: 50)

                    TableColumn("Título", value: \.title)

                    TableColumn("Sons") { reaction in
                        guard let sounds = reaction.sounds else { return Text("0") }
                        return Text("\(sounds.count)")
                    }
                    .width(min: 50, max: 50)

                    TableColumn("Data de última atualização") { reaction in
                        return Text(reaction.lastUpdate.formattedDate)
                    }
                }
                .contextMenu(forSelectionType: Sound.ID.self) { items in
                    Section {
                        Button("Editar Reação") {
                            guard let selectedItemId = items.first else { return }
                            viewModel.onEditReactionSelected(reactionId: selectedItemId)
                        }
                    }
                } primaryAction: { items in
                    guard let selectedItemId = items.first else { return }
                    viewModel.onEditReactionSelected(reactionId: selectedItemId)
                }
                .searchable(text: $viewModel.searchText)

                HStack(spacing: 20) {
                    HStack(spacing: 10) {
                        Button {
                            viewModel.onCreateNewReactionSelected()
                        } label: {
                            Image(systemName: "plus")
                        }

                        Button {
                            viewModel.onRemoveReactionSelected()
                        } label: {
                            Image(systemName: "minus")
                        }
                    }

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

//                    Button("Importar das Pastas") {
//                        print("")
//                    }
//                    .disabled(!isInEditMode)

                    Spacer()

                    Button {
                        viewModel.onMoveReactionDownSelected()
                    } label: {
                        Label("Mover", systemImage: "chevron.down")
                    }
                    .disabled(viewModel.selectedItem == nil)

                    Button {
                        viewModel.onMoveReactionUpSelected()
                    } label: {
                        Label("Mover", systemImage: "chevron.up")
                    }
                    .disabled(viewModel.selectedItem == nil)

                    Text("\(viewModel.reactions.count.formattedString) itens")

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
                .frame(height: 40)
            }
            .navigationTitle("Reações")
            .padding()
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
                    saveAction: { Task { await viewModel.onSaveReactionSelected() } },
                    dismissSheet: { viewModel.reactionForEditing = nil },
                    lastPosition: viewModel.reactions.count
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
                LoadingView()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ReactionsCRUDView()
}
