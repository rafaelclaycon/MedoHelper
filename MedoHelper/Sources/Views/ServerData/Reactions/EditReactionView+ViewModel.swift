//
//  EditReactionView+ViewModel.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 25/10/24.
//

import Foundation

extension EditReactionView {

    @MainActor
    final class ViewModel: ObservableObject {

        @Published var reaction: ReactionDTO

        @Published var editableReactionTitle: String = ""
        @Published var editableImageUrl: String = ""
        @Published var didLoadSoundInfo: Bool = false
        @Published var reactionSounds: [ReactionSoundForDisplay] = []

        @Published var selectedItem: ReactionSoundForDisplay.ID?

        @Published var showAddSheet: Bool = false

        @Published var didChangeSoundOrder: Bool = false

        @Published var isLoading = false

        // Alert
        @Published var showingAlert = false
        @Published var alertTitle = ""
        @Published var alertMessage = ""
        @Published var alertType: AlertType = .singleOptionInformative

        // Progress View
        @Published var showSendProgress = false
        @Published var progressAmount = 0.0
        @Published var totalAmount = 2.0
        @Published var modalMessage = ""

        // MARK: - Private Variables

        public let isEditing: Bool
        private let saveAction: (ReactionDTO) -> Void
        private let dismissSheet: () -> Void
        private let originalReaction: ReactionDTO

        // MARK: - Computed Properties

        private var didChange: Bool {
            let titleOrImageChanged = editableReactionTitle != originalReaction.title || editableImageUrl != originalReaction.image
            let countChanged = reactionSounds.count != originalReaction.sounds?.count

            return titleOrImageChanged || countChanged || didChangeSoundOrder
        }

        // MARK: - Initializer

        init(
            reaction: ReactionDTO,
            saveAction: @escaping (ReactionDTO) -> Void,
            dismissSheet: @escaping () -> Void
        ) {
            self.isEditing = reaction.title != ""
            self.reaction = reaction
            self.saveAction = saveAction
            self.dismissSheet = dismissSheet
            self.originalReaction = reaction
        }
    }
}

// MARK: - User Actions

extension EditReactionView.ViewModel {

    public func onViewLoad() async {
        await loadSoundList()
    }

    public func onCancelSelected() {
        dismissSheet()
    }

    public func onCreateOrUpdateSelected() async {
        if isEditing {
            await updateReaction()
        }
//        else {
//            createContent()
//        }
    }

    public func onMoveSoundDownSelected() {
        moveDown(selectedID: selectedItem)
        didChangeSoundOrder = true
    }

    public func onMoveSoundUpSelected() {
        moveUp(selectedID: selectedItem)
        didChangeSoundOrder = true
    }
}

// MARK: - Internal Operations

extension EditReactionView.ViewModel {

    private func loadSoundList() async {
        //totalAmount = Double(reactions.count)
        //showSendProgress = true
        //modalMessage = "Enviando Dados..."
        //progressAmount = 0

        do {
            guard let reactSounds = reaction.sounds else { return }

            print("Reactions count: \(reactSounds.count)")

            var toBeSet: [ReactionSoundForDisplay] = []

            for reactionSound in reactSounds {
                let soundDetailUrl = URL(string: serverPath + "v3/sound/\(reactionSound.soundId)")!
                let serverSound: SoundDTO = try await APIClient().get(from: soundDetailUrl)

                let auhtorDetailUrl = URL(string: serverPath + "v3/author/\(serverSound.authorId)")!
                let author: Author = try await APIClient().get(from: auhtorDetailUrl)

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

            self.reactionSounds = toBeSet

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

    private func updateReaction() async {
        totalAmount = 3.0
        showSendProgress = true
        modalMessage = "Atualizando Reação..."
        progressAmount = 0

        print("UPDATE REACTION - Set .now as lastUpdate on Reaction")
        let newReaction = ReactionDTO(
            id: reaction.id,
            title: editableReactionTitle,
            position: originalReaction.position,
            image: reaction.image,
            lastUpdate: Date.now.toISO8601String()
        )

        do {
            print("UPDATE REACTION - Update Reaction data")
            let updateUrl = URL(string: serverPath + "v4/reaction/\(reactionsPassword)")!
            guard try await APIClient().put(in: updateUrl, data: newReaction) else {
                showAlert("Erro ao Atualizar Reação", "PUT")
                return
            }

            progressAmount = 1.0
            modalMessage = "Apagando Sons Antigos..."

            print("UPDATE REACTION - Delete previous sounds of Reaction")
            let soundsDeleteUrl = URL(string: serverPath + "v4/delete-reaction-sounds/\(newReaction.id)/\(reactionsPassword)")!
            guard try await APIClient().delete(in: soundsDeleteUrl) else {
                showAlert("Erro ao Apagar os Sons da Reação", "DELETE")
                return
            }

            progressAmount = 2.0
            modalMessage = "Adicionando Sons Novos..."

            print("UPDATE REACTION - Add new sounds to Reaction")
            let soundsAddUrl = URL(string: serverPath + "v4/add-sounds-to-reaction/\(reactionsPassword)")!
            let newSounds = reactionSounds.asServerCompatibleType(reactionId: reaction.id)
            guard let _ = try await APIClient().post(data: newSounds, to: soundsAddUrl) else {
                showAlert("Erro ao Inserir Novos Sons na Reação", "POST")
                return
            }

            progressAmount = 3.0

            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
                self.showSendProgress = false
                self.saveAction(self.reaction)
                self.dismissSheet()
            }
        } catch {
            print(error)
        }
    }

    private func showAlert(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - List Item Moving

extension EditReactionView.ViewModel {

    private func moveUp(selectedID: ReactionSoundForDisplay.ID?) {
        guard
            let selectedID = selectedID,
            let index = reactionSounds.firstIndex(where: { $0.id == selectedID }),
            index > 0
        else { return }
        reactionSounds.swapAt(index, index - 1)
        updatePositions()
    }

    private func moveDown(selectedID: ReactionSoundForDisplay.ID?) {
        guard
            let selectedID = selectedID,
            let index = reactionSounds.firstIndex(where: { $0.id == selectedID }),
            index < reactionSounds.count - 1
        else { return }
        reactionSounds.swapAt(index, index + 1)
        updatePositions()
    }

    private func updatePositions() {
        for (index, _) in reactionSounds.enumerated() {
            reactionSounds[index].position = index + 1
        }
    }
}
