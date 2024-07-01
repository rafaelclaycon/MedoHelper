//
//  EditReactionView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 01/05/24.
//

import SwiftUI

struct EditReactionView: View {

    @Binding var isBeingShown: Bool

    let onChangeAction: () -> Void

    @State private var editableReactionTitle: String = ""
    @State private var editableImageUrl: String = ""
    @State private var didLoadSoundInfo: Bool = false
    @State private var reactionSounds: [ReactionSoundForDisplay] = []

    @State private var selectedItem: ReactionSoundForDisplay.ID?

    @State private var showAddSheet: Bool = false

    @State private var originalReaction: ReactionDTO?
    @State private var didChangeSoundOrder: Bool = false

    // Alert
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertType: AlertType = .singleOptionInformative

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

    private var idText: String {
        guard let reaction = helper.reaction else { return "" }
        return "ID: \(reaction.id)"
    }

    private var didChange: Bool {
        guard let originalReac = helper.reaction else { return false }

        let titleOrImageChanged = editableReactionTitle != originalReac.title || editableImageUrl != originalReac.image
        let countChanged = reactionSounds.count != originalReac.sounds?.count

        return titleOrImageChanged || countChanged || didChangeSoundOrder
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
                Text(idText)
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

                    Button {
                        didChangeSoundOrder = true
                        moveDown(selectedID: selectedItem)
                    } label: {
                        Label("Mover Para Baixo", systemImage: "chevron.down")
                    }
                    .disabled(selectedItem == nil)

                    Button {
                        didChangeSoundOrder = true
                        moveUp(selectedID: selectedItem)
                    } label: {
                        Label("Mover Para Cima", systemImage: "chevron.up")
                    }
                    .disabled(selectedItem == nil)

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
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Functions

    private func populateSoundsWithInfo() {
        Task {
            //totalAmount = Double(reactions.count)
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

            guard let oldReaction = helper.reaction else {
                showAlert("Incapaz de Obter ID", "Verifique se uma Reação válida foi selecionada.")
                return
            }

            print("UPDATE REACTION - Set .now as lastUpdate on Reaction")
            let newReaction = ReactionDTO(
                id: oldReaction.id,
                title: editableReactionTitle,
                position: originalReaction?.position ?? 0,
                image: reactionImageUrl,
                lastUpdate: Date.now.toISO8601String()
            )

            print("UPDATE REACTION - Update Reaction data")
            let updateUrl = URL(string: serverPath + "v4/reaction/\(reactionsPassword)")!
            guard try await NetworkRabbit.put(in: updateUrl, data: newReaction) else {
                showAlert("Erro ao Atualizar Reação", "PUT")
                return
            }

            await MainActor.run {
                progressAmount = 1.0
                modalMessage = "Apagando Sons Antigos..."
            }

            print("UPDATE REACTION - Delete previous sounds of Reaction")
            let soundsDeleteUrl = URL(string: serverPath + "v4/delete-reaction-sounds/\(newReaction.id)/\(reactionsPassword)")!
            guard try await NetworkRabbit.delete(in: soundsDeleteUrl) else {
                showAlert("Erro ao Apagar os Sons da Reação", "DELETE")
                return
            }

            await MainActor.run {
                progressAmount = 2.0
                modalMessage = "Adicionando Sons Novos..."
            }

            print("UPDATE REACTION - Add new sounds to Reaction")
            let soundsAddUrl = URL(string: serverPath + "v4/add-sounds-to-reaction/\(reactionsPassword)")!
            let newSounds = reactionSounds.asServerCompatibleType(reactionId: oldReaction.id)
            guard let _ = try await NetworkRabbit.post(data: newSounds, to: soundsAddUrl) else {
                showAlert("Erro ao Inserir Novos Sons na Reação", "POST")
                return
            }

            await MainActor.run {
                progressAmount = 3.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
                showSendProgress = false
                isBeingShown = false
                onChangeAction()
            }
        }
    }

    private func showAlert(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }

    private func moveUp(selectedID: ReactionSoundForDisplay.ID?) {
        guard let selectedID = selectedID,
              let index = reactionSounds.firstIndex(where: { $0.id == selectedID }),
              index > 0 else { return }
        reactionSounds.swapAt(index, index - 1)
        updatePositions()
    }

    private func moveDown(selectedID: ReactionSoundForDisplay.ID?) {
        guard let selectedID = selectedID,
              let index = reactionSounds.firstIndex(where: { $0.id == selectedID }),
              index < reactionSounds.count - 1 else { return }
        reactionSounds.swapAt(index, index + 1)
        updatePositions()
    }

    private func updatePositions() {
        for (index, _) in reactionSounds.enumerated() {
            reactionSounds[index].position = index + 1
        }
    }
}

#Preview {
    EditReactionView(
        isBeingShown: .constant(true),
        onChangeAction: { }
    )
}
