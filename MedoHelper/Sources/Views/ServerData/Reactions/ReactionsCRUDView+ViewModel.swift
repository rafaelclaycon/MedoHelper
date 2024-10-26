//
//  ReactionsCRUDView+ViewModel.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 23/10/24.
//

import Foundation

extension ReactionsCRUDView {

    @MainActor
    final class ViewModel: ObservableObject {

        @Published var reactions: [ReactionDTO] = []

        @Published var searchText = ""
        @Published var selectedItem: ReactionDTO.ID?
        @Published var reaction: ReactionDTO? = nil
        @Published var isLoading: Bool = false

        @Published var reactionForEditing: ReactionDTO?

        @Published var didChangeReactionOrder: Bool = false

        // Progress View
        @Published var isSending = false
        @Published var progressAmount = 0.0
        @Published var totalAmount = 2.0
        @Published var modalMessage = ""

        // Alert
        @Published var showAlert = false
        @Published var alertType: AlertType = .singleOptionInformative
        @Published var alertTitle: String = ""
        @Published var alertMessage: String = ""

        // MARK: - Stored Properties

        private let reactionRepository: ReactionRepositoryProtocol

        // MARK: - Computed Properties

        var searchResults: [ReactionDTO] {
            if searchText.isEmpty {
                return reactions
            } else {
                return reactions.filter { reaction in
                    return reaction.title.contains(searchText.preparedForComparison())
                }
            }
        }

        var isSendDataButtonDisabled: Bool {
            reactions.isEmpty || !didChangeReactionOrder
        }

        var selectedReactionName: String {
            guard
                let selectedItem,
                let reaction = reaction(withId: selectedItem)
            else { return "" }
            return reaction.title
        }

        // MARK: - Initializer

        init(
            reactionRepository: ReactionRepositoryProtocol
        ) {
            self.reactionRepository = reactionRepository
        }
    }
}

// MARK: - User Actions

extension ReactionsCRUDView.ViewModel {

    func onViewAppear() async {
        await loadReactions()
    }

    func onCreateNewReactionSelected() {
        reactionForEditing = .init(position: 0, title: "")
    }

    func onRemoveReactionSelected() {
        alertType = .twoOptionsOneDelete
        showAlert = true
    }

    func onImportAndSendPreExistingReactionsSelected() async {
        await importAndSendPreExistingReactions()
    }

    func onEditReactionSelected(reactionId: String) {
        guard let reaction = reaction(withId: reactionId) else { return }
        reactionForEditing = reaction
    }

    func onMoveReactionUpSelected() {
        didChangeReactionOrder = true
        moveUp(selectedID: selectedItem)
    }

    func onMoveReactionDownSelected() {
        didChangeReactionOrder = true
        moveDown(selectedID: selectedItem)
    }

    func onSendDataSelected() async {
        await sendAll()
    }

    func onSaveReactionSelected(reaction: ReactionDTO) {
        if let index = reactions.firstIndex(where: { $0.id == reaction.id }) {
            reactions[index] = reaction
        } else {
            reactions.append(reaction)
        }
    }

    func onConfirmRemoveReactionSelected() async {

    }
}

// MARK: - Internal Operations

extension ReactionsCRUDView.ViewModel {

    private func loadReactions() async {
        isLoading = true

        do {
            self.reactions = try await reactionRepository.allReactions()
        } catch {
            print(error)
            isLoading = false
            alertType = .singleOptionError
            alertTitle = "Não Foi Possível Carregar as Reações"
            alertMessage = error.localizedDescription
            showAlert = true
        }

        isLoading = false
    }

    private func reaction(withId id: String) -> ReactionDTO? {
        for reaction in reactions {
            if reaction.id == id {
                return reaction
            }
        }
        return nil
    }

    private func importAndSendPreExistingReactions() async {
        guard reactions.isEmpty else {
            return print("TEM CERTEZA QUE QUER FAZER ISSO?")
        }

        reactions = Bundle.main.decodeJSON("reactions_data.json")
        reactions.sort(by: { $0.position < $1.position })

        for i in 0...(reactions.count-1) {
            reactions[i].lastUpdate = Date.now.toISO8601String()
            if let reactionSounds = reactions[i].sounds, !reactionSounds.isEmpty {
                for j in 0...(reactions[i].sounds!.count-1) {
                    reactions[i].sounds![j].dateAdded = Date.now.toISO8601String()
                }
            }
        }

        await onSendDataSelected()
    }

    private func sendAll() async {
        totalAmount = Double(reactions.count)
        isSending = true
        modalMessage = "Enviando Dados..."
        progressAmount = 0

        do {
            try await reactionRepository.removeAllReactions()

            print("Reactions count: \(reactions.count)")
            try await reactionRepository.save(
                reactions: reactions,
                onItemDidSend: { progressAmount += 1 }
            )

            isSending = false
            didChangeReactionOrder = false
        } catch ReactionRepositoryError.errorDeletingReactions {
            afterSendingError(title: "Erro ao Tentar Remover as Reações")
        } catch ReactionRepositoryError.errorDeletingReactionSounds {
            afterSendingError(title: "Erro ao Tentar Remover os Sons das Reações")
        } catch {
            print(error)
            afterSendingError(
                title: "Erro Desconhecido ao Tentar Enviar Reações",
                message: error.localizedDescription
            )
        }
    }

    private func afterSendingError(title: String, message: String = "") {
        isSending = false
        alertType = .singleOptionError
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

// MARK: - List Item Moving

extension ReactionsCRUDView.ViewModel {

    private func moveUp(selectedID: ReactionSoundForDisplay.ID?) {
        guard
            let selectedID = selectedID,
            let index = reactions.firstIndex(where: { $0.id == selectedID }),
            index > 0
        else { return }
        reactions.swapAt(index, index - 1)
        updatePositions()
    }

    private func moveDown(selectedID: ReactionSoundForDisplay.ID?) {
        guard
            let selectedID = selectedID,
            let index = reactions.firstIndex(where: { $0.id == selectedID }),
            index < reactions.count - 1
        else { return }
        reactions.swapAt(index, index + 1)
        updatePositions()
    }

    private func updatePositions() {
        for (index, _) in reactions.enumerated() {
            reactions[index].position = index + 1
        }
    }
}
