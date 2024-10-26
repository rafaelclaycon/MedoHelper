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

        @Published var reaction: HelperReaction

        @Published var editableReactionTitle: String = ""
        @Published var editableImageUrl: String = ""
        @Published var didLoadSoundInfo: Bool = false
        @Published var reactionSounds: [ReactionSoundForDisplay] = []

        @Published var selectedItem: ReactionSoundForDisplay.ID?

        @Published var showAddSheet: Bool = false

        @Published var didChangeSounds: Bool = false

        @Published var isLoading = false
        @Published var isSending = false

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
        private let reactionRepository: ReactionRepositoryProtocol
        private let saveAction: (HelperReaction) -> Void
        private let dismissSheet: () -> Void
        private let originalReaction: HelperReaction

        // MARK: - Computed Properties

        var reactionDidChange: Bool {
            let titleOrImageChanged = editableReactionTitle != originalReaction.title || editableImageUrl != originalReaction.image
            let countChanged = reactionSounds.count != originalReaction.sounds?.count

            return titleOrImageChanged || countChanged || didChangeSounds
        }

        // MARK: - Initializer

        init(
            reaction: HelperReaction,
            reactionRepository: ReactionRepositoryProtocol = ReactionRepository(),
            saveAction: @escaping (HelperReaction) -> Void,
            dismissSheet: @escaping () -> Void
        ) {
            self.isEditing = reaction.title != ""
            self.reaction = reaction
            self.reactionRepository = reactionRepository
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

    public func onAddSoundSelected() {
        showAddSheet = true
    }

    public func onNewSoundAdded(newSound: Sound) {
        let reactionSoundForDisplay = ReactionSoundForDisplay(
            id: nil,
            soundId: newSound.id,
            title: newSound.title,
            authorName: newSound.authorName ?? "",
            dateAdded: Date.now.iso8601String,
            position: reactionSounds.count + 1
        )
        reactionSounds.append(reactionSoundForDisplay)
        updatePositions()
        didChangeSounds = true
    }

    public func onRemoveSoundSelected() {
        guard let selectedItem else { return }
        reactionSounds.removeAll(where: { $0.id == selectedItem })
        updatePositions()
        didChangeSounds = true
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
        didChangeSounds = true
    }

    public func onMoveSoundUpSelected() {
        moveUp(selectedID: selectedItem)
        didChangeSounds = true
    }
}

// MARK: - Internal Operations

extension EditReactionView.ViewModel {

    private func loadSoundList() async {
        isLoading = true

        do {
            guard let reactSounds = reaction.sounds else { return }
            print("Reaction sound count: \(reactSounds.count)")

            self.reactionSounds = try await reactionRepository.reactionSoundsWithAllData(reactSounds)

            isLoading = false
        } catch {
            print(error)
            isLoading = false
            showAlert("Erro Ao Carregar Sons", error.localizedDescription)
        }
    }

    private func updateReaction() async {
        totalAmount = 3.0
        isSending = true
        modalMessage = "Atualizando Reação..."
        progressAmount = 0

        let newReaction = HelperReaction(
            id: reaction.id,
            title: editableReactionTitle,
            position: originalReaction.position,
            image: reaction.image,
            lastUpdate: Date.now.iso8601String
        )

        do {
            try await reactionRepository.update(reaction: newReaction)

            progressAmount = 1.0
            modalMessage = "Apagando Sons Antigos..."

            try await reactionRepository.removeAllSoundsOf(reactionId: reaction.id)

            progressAmount = 2.0
            modalMessage = "Adicionando Sons Novos..."

            let newSounds = reactionSounds.serverCompatibleSounds(reactionId: reaction.id)
            try await reactionRepository.add(sounds: newSounds)

            progressAmount = 3.0

            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
                self.isSending = false
                self.saveAction(self.reaction)
                self.dismissSheet()
            }
        } catch {
            print(error)
            self.isSending = false
            showAlert("Erro Ao Atualizar Reação", error.localizedDescription)
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
