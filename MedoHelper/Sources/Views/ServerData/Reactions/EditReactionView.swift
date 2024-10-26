//
//  EditReactionView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 01/05/24.
//

import SwiftUI

struct EditReactionView: View {

    @StateObject private var viewModel: ViewModel

    // MARK: - Initializer

    init(
        reaction: HelperReaction,
        saveAction: @escaping (HelperReaction) -> Void,
        dismissSheet: @escaping () -> Void
    ) {
        self._viewModel = StateObject(
            wrappedValue: ViewModel(
                reaction: reaction,
                saveAction: saveAction,
                dismissSheet: dismissSheet
            )
        )
    }

    // MARK: - View Body

    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Text(viewModel.isEditing ? "Editando Reação \"\(viewModel.reaction.title)\"" : "Criando Nova Reação")
                    .font(.title)
                    .bold()

                Spacer()
            }

            HStack {
                Text(viewModel.reaction.id)
                    .foregroundColor(viewModel.isEditing ? .primary : .gray)

                Spacer()
            }

            TextField("Título", text: $viewModel.reaction.title)

            TextField("URL da Imagem", text: $viewModel.reaction.image)

            VStack {
                Table(viewModel.reactionSounds, selection: $viewModel.selectedItem) {
                    TableColumn("Posição") { reaction in
                        Text("\(reaction.position)")
                    }
                    .width(min: 50, max: 50)

                    TableColumn("Som", value: \.title)

                    TableColumn("Autor", value: \.authorName)

                    TableColumn("Data de Adição") { soundForDisplay in
                        return Text(soundForDisplay.dateAdded.formattedDate)
                    }
                }

                HStack(spacing: 20) {
                    HStack(spacing: 10) {
                        Button {
                            viewModel.onAddSoundSelected()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .sheet(isPresented: $viewModel.showAddSheet) {
                            SoundSearchView(
                                addAction: { sound in
                                    viewModel.onNewSoundAdded(newSound: sound)
                                }
                            )
                            .frame(minWidth: 800, minHeight: 500)
                        }

                        Button {
                            viewModel.onRemoveSoundSelected()
                        } label: {
                            Image(systemName: "minus")
                        }
                    }

                    Spacer()

                    Button {
                        viewModel.onMoveSoundDownSelected()
                    } label: {
                        Label("Mover Para Baixo", systemImage: "chevron.down")
                    }
                    .disabled(viewModel.selectedItem == nil)

                    Button {
                        viewModel.onMoveSoundUpSelected()
                    } label: {
                        Label("Mover Para Cima", systemImage: "chevron.up")
                    }
                    .disabled(viewModel.selectedItem == nil)

                    Text("\(viewModel.reactionSounds.count.formattedString) sons")
                }
                .frame(height: 40)
            }

            //Spacer()

            HStack(spacing: 15) {
                Spacer()

                Button {
                    viewModel.onCancelSelected()
                } label: {
                    Text("Cancelar")
                        .padding(.horizontal)
                }
                .keyboardShortcut(.cancelAction)

                Button {
                    Task {
                        await viewModel.onCreateOrUpdateSelected()
                    }
                } label: {
                    Text(viewModel.isEditing ? "Atualizar" : "Criar")
                        .padding(.horizontal)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!viewModel.reactionDidChange)
            }
        }
        .padding(.all, 26)
        .onAppear {
            Task {
                await viewModel.onViewLoad()
            }
        }
        .sheet(isPresented: $viewModel.isSending) {
            SendingProgressView(
                message: viewModel.modalMessage,
                currentAmount: viewModel.progressAmount,
                totalAmount: viewModel.totalAmount
            )
        }
        .alert(isPresented: $viewModel.showingAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .overlay {
            if viewModel.isLoading {
                LoadingView(message: "Carregando sons...")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EditReactionView(
        reaction: .init(position: 1, title: "Exemplo"),
        saveAction: { _ in },
        dismissSheet: {}
    )
}
