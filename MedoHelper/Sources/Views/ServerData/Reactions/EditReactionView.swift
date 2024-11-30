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
        sounds: [Sound],
        saveAction: @escaping () -> Void,
        dismissSheet: @escaping () -> Void,
        lastPosition: Int
    ) {
        self._viewModel = StateObject(
            wrappedValue: ViewModel(
                reaction: reaction,
                sounds: sounds,
                saveAction: saveAction,
                dismissSheet: dismissSheet,
                lastPosition: lastPosition
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

            HStack(spacing: 15) {
                Text("📸")

                TextField("Texto de Crédito ao Autor da Imagem", text: $viewModel.reaction.attributionText)
                    .textCase(.uppercase)

                TextField("URL de Crédito ao Autor da Imagem", text: $viewModel.reaction.attributionURL)
            }

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
                                sounds: viewModel.allSounds,
                                addAction: { sound in
                                    viewModel.onNewSoundAdded(newSound: sound)
                                },
                                soundExistsOnReaction: { soundId in
                                    viewModel.doesSoundIdExist(soundId)
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
                await viewModel.onViewLoaded()
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
                LoadingView(message: "Carregando sons da Reação...")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    EditReactionView(
        reaction: .init(position: 1, title: "Exemplo"),
        sounds: [.init(title: "Que isso")],
        saveAction: {},
        dismissSheet: {},
        lastPosition: 1
    )
}
