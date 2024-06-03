//
//  EditReactionView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 01/05/24.
//

import SwiftUI

struct EditReactionView: View {

    @Binding var isBeingShown: Bool

    @State private var editableReactionTitle: String = ""
    @State private var editableImageUrl: String = ""
    @State private var didLoadSoundInfo: Bool = false
    @State private var reactionSounds: [ReactionSoundForDisplay] = []

    @State private var selectedItem: ReactionSoundForDisplay.ID?

    @State private var showAddSheet: Bool = false

    @State private var originalReaction: ReactionDTO?

    // Progress View
    @State private var showSendProgress = false
    @State private var progressAmount = 0.0
    @State private var totalAmount = 2.0
    @State private var modalMessage = ""

    // MARK: - Computed Properties

    private var isEditing: Bool {
        return helper.reaction != nil
    }

    private var reactionTitle: String {
        guard let reaction = helper.reaction else { return "" }
        return reaction.title
    }

    private var reactionImageUrl: String {
        guard let reaction = helper.reaction else { return "" }
        return reaction.image
    }

    private var id: String {
        guard let reaction = helper.reaction else { return "" }
        return "ID: \(reaction.id)"
    }

    private var didChange: Bool {
        guard let originalReac = helper.reaction else { return false }
        return editableReactionTitle != originalReac.title ||
            editableImageUrl != originalReac.image ||
            reactionSounds.count != originalReac.sounds?.count
    }

    // MARK: - Environment

    @EnvironmentObject var helper: EditReactionHelper

    // MARK: - View Body

    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Text(isEditing ? "Editando Reação \"\(reactionTitle)\"" : "Criando Nova Reação")
                    .font(.title)
                    .bold()

                Spacer()
            }

            HStack {
                Text(id)
                    .foregroundColor(isEditing ? .primary : .gray)

                Spacer()
            }

            TextField("Título", text: $editableReactionTitle)

            TextField("URL da Imagem", text: $editableImageUrl)

            VStack {
                Table(reactionSounds, selection: $selectedItem) {
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
                            showAddSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .sheet(isPresented: $showAddSheet) {
                            SoundSearchView(addAction: { sound in
                                reactionSounds.append(.init(
                                    id: nil,
                                    soundId: sound.id,
                                    title: sound.title,
                                    authorName: sound.authorName ?? "",
                                    dateAdded: Date.now.toISO8601String(),
                                    position: reactionSounds.count + 1
                                ))
                            })
                            .frame(minWidth: 800, minHeight: 500)
                        }

                        Button {
                            // print((selectedItem ?? "") as String)
                            //                        alertType = .twoOptionsOneDelete
                            //                        showAlert = true
                        } label: {
                            Image(systemName: "minus")
                        }
                    }

                    Spacer()

                    Text("\(reactionSounds.count.formattedString) sons")
                }
                .frame(height: 40)
            }

            //Spacer()

            HStack(spacing: 15) {
                Spacer()

                Button {
                    isBeingShown = false
                } label: {
                    Text("Cancelar")
                        .padding(.horizontal)
                }
                .keyboardShortcut(.cancelAction)

                Button {
                    if isEditing {
                        updateReaction()
                    }
//                    else {
//                        createContent()
//                    }
                } label: {
                    Text(isEditing ? "Atualizar" : "Criar")
                        .padding(.horizontal)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!didChange)
            }
        }
        .padding(.all, 26)
        .onAppear {
            originalReaction = helper.reaction
            editableReactionTitle = reactionTitle
            editableImageUrl = reactionImageUrl
            populateSoundsWithInfo()
        }
    }

    // MARK: - Functions

    private func populateSoundsWithInfo() {
        Task {
            totalAmount = Double(reactions.count)
            //showSendProgress = true
            //modalMessage = "Enviando Dados..."
            //progressAmount = 0

            do {
                guard helper.reaction != nil else { return }
                guard let reactSounds = helper.reaction?.sounds else { return }

                print("Reactions count: \(reactSounds.count)")

                var toBeSet: [ReactionSoundForDisplay] = []

                for reactionSound in reactSounds {
                    let soundDetailUrl = URL(string: serverPath + "v3/sound/\(reactionSound.soundId)")!
                    let serverSound: SoundDTO = try await NetworkRabbit.get(from: soundDetailUrl)

                    let auhtorDetailUrl = URL(string: serverPath + "v3/author/\(serverSound.authorId)")!
                    let author: Author = try await NetworkRabbit.get(from: auhtorDetailUrl)

                    toBeSet.append(
                        .init(
                            id: reactionSound.id,
                            soundId: reactionSound.soundId,
                            title: serverSound.title,
                            authorName: author.name,
                            dateAdded: reactionSound.dateAdded,
                            position: reactionSound.position
                        )
                    )
                }

                await MainActor.run {
                    self.reactionSounds = toBeSet
                }

//                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
//                    showSendProgress = false
//                }
            } catch {
                print(error)
//                alertType = .singleOptionInformative
//                alertTitle = "Falha ao Criar o Som"
//                alertMessage = error.localizedDescription
                // showSendProgress = false
                // return showingAlert = true
            }
        }
    }

    private func updateReaction() {
        Task {
            await MainActor.run {
                totalAmount = 3.0
                showSendProgress = true
                modalMessage = "Atualizando Reação..."
                progressAmount = 0
            }

            let newReaction = ReactionDTO(
                id: id,
                title: editableReactionTitle,
                position: originalReaction?.position ?? 0,
                image: reactionImageUrl,
                lastUpdate: Date.now.toISO8601String(),
                sounds: reactionSounds.asBasicType
            )

            let updateUrl = URL(string: serverPath + "v4/reaction/\(reactionsPassword)")!
            guard try await NetworkRabbit.put(in: updateUrl, data: updateUrl) else {
                return print("ERROR")
            }

            await MainActor.run {
                progressAmount = 1.0
                modalMessage = "Apagando Sons Antigos..."
            }

            let soundsDeleteUrl = URL(string: serverPath + "v4/delete-reaction-sounds/\(newReaction.id)/\(reactionsPassword)")!
            guard try await NetworkRabbit.delete(in: soundsDeleteUrl) else {
                print("Não foi possível apagar os sons da Reação.")
                return
            }

            await MainActor.run {
                progressAmount = 2.0
                modalMessage = "Adicionando Sons Novos..."
            }

            let soundsAddUrl = URL(string: serverPath + "v4/add-sounds-to-reaction/\(reactionsPassword)")!
            let _ = try await NetworkRabbit.post(data: newReaction.sounds, to: soundsAddUrl)

            await MainActor.run {
                progressAmount = 3.0
            }
        }
    }
}

#Preview {
    EditReactionView(isBeingShown: .constant(true))
}
