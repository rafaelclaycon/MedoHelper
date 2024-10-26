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
        private let reactionRepository: ReactionRepositoryProtocol
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
            reactionRepository: ReactionRepositoryProtocol = ReactionRepository(),
            saveAction: @escaping (ReactionDTO) -> Void,
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
        showSendProgress = true
        modalMessage = "Atualizando Reação..."
        progressAmount = 0

        let newReaction = ReactionDTO(
            id: reaction.id,
            title: editableReactionTitle,
            position: originalReaction.position,
            image: reaction.image,
            lastUpdate: Date.now.toISO8601String()
        )

        do {
            try await reactionRepository.update(reaction: newReaction)

            progressAmount = 1.0
            modalMessage = "Apagando Sons Antigos..."

            try await reactionRepository.removeAllSoundsOf(reactionId: reaction.id)

            progressAmount = 2.0
            modalMessage = "Adicionando Sons Novos..."

            let newSounds = reactionSounds.asServerCompatibleType(reactionId: reaction.id)
            try await reactionRepository.add(sounds: newSounds)

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
