//
//  ReactionsCRUDView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 01/05/24.
//

import SwiftUI

struct ReactionsCRUDView: View {

    @StateObject private var viewModel = ViewModel(apiClient: APIClient())

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

                    //                .alert(isPresented: $showAlert) {
                    //                    switch alertType {
                    //                    case .singleOptionInformative:
                    //                        return Alert(
                    //                            title: Text("Som Removido Com Sucesso"),
                    //                            message: Text("O som \"\(selectedSoundTitle)\" foi marcado como removido no servidor e a mudança será propagada para todos os clientes na próxima sincronização."),
                    //                            dismissButton: .cancel(Text("OK")) {
                    //                                fetchSounds()
                    //                            }
                    //                        )
                    //
                    //                    case .twoOptionsOneDelete:
                    //                        return Alert(title: Text("Remover \"\(selectedSoundTitle)\""), message: Text("Tem certeza de que deseja remover o som \"\(selectedSoundTitle)\"? A mudança será sincronizada com o servidor e propagada para todos os clientes na próxima sincronização."), primaryButton: .destructive(Text("Remover"), action: {
                    //                            guard let selectedItem else { return }
                    //                            removeSound(withId: selectedItem)
                    //                        }), secondaryButton: .cancel(Text("Cancelar")))
                    //
                    //                    default:
                    //                        return Alert(title: Text("Houve um Problema Ao Tentar Marcar o Som como Removido"), message: Text(alertErrorMessage), dismissButton: .cancel(Text("OK")))
                    //                    }
                    //                }

                    Button("Importar de Arquivo JSON") {
                        viewModel.onImportAndSendPreExistingReactionsSelected()
                    }

//                    Button("Importar das Pastas") {
//                        print("")
//                    }
//                    .disabled(!isInEditMode)

                    Spacer()

                    //                Button("Copiar títulos") {
                    //                    copyTitlesToClipboard()
                    //                }

                    //                Button("Enviar Sons Já no App") {
                    //                    showMoveDataSheet()
                    //                }
                    //                .sheet(isPresented: $showAddAlreadyOnAppSheet) {
                    //                    MoveDataToServerView(isBeingShown: $showAddAlreadyOnAppSheet,
                    //                                         data: fixedData!,
                    //                                         chunkSize: 10,
                    //                                         endpointEnding: "v3/import-sounds/\(assetOperationPassword)")
                    //                        .frame(minWidth: 800, minHeight: 500)
                    //                }

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
                        viewModel.onSendDataSelected()
                    } label: {
                        Text("Enviar Dados")
                            .padding(.horizontal)
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(viewModel.didChangeReactionOrder)
                }
                .frame(height: 40)
            }
            .navigationTitle("Reações")
            .padding()
            .sheet(isPresented: $viewModel.showSendProgress) {
                SendingProgressView(
                    isBeingShown: $viewModel.showSendProgress,
                    message: $viewModel.modalMessage,
                    currentAmount: $viewModel.progressAmount,
                    totalAmount: $viewModel.totalAmount
                )
            }
            .sheet(item: $viewModel.reactionForEditing) { reaction in
                EditReactionView(
                    reaction: reaction,
                    saveAction: { viewModel.onSaveReactionSelected(reaction: $0) }
                )
                .frame(minWidth: 1024, minHeight: 700)
            }
            .onAppear {
                viewModel.onViewAppear()
            }
        }
        .overlay {
            if viewModel.showLoadingView {
                LoadingView()
            }
        }
    }
}

#Preview {
    ReactionsCRUDView()
}
