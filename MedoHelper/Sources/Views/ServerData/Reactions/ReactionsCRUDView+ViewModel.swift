//
//  ReactionsCRUDView+ViewModel.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 23/10/24.
//

import SwiftUI

extension ReactionsCRUDView {

    @MainActor
    final class ViewModel: ObservableObject {

        @Published var state: LoadingState<ReactionsCRUDModel> = .loading

        @Published var reactions: [HelperReaction] = []
        @Published var sounds: [Sound] = []

        @Published var searchText = ""
        @Published var selectedItemId: String?
        @Published var reaction: HelperReaction? = nil
        @Published var isLoading: Bool = false
        @Published var loadingMessage: String = ""

        @Published var reactionForEditing: HelperReaction?

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

        var searchResults: [HelperReaction] {
            guard case .loaded(let data) = state else {
                return []
            }
            return data.reactions
//            if searchText.isEmpty {
//                return reactions
//            } else {
//                return reactions.filter { reaction in
//                    return reaction.title.contains(searchText.preparedForComparison())
//                }
//            }
        }

        var isSendDataButtonDisabled: Bool {
            guard case .loaded(let data) = state else {
                return true
            }
            return data.reactions.isEmpty || !didChangeReactionOrder
        }

        var selectedReactionName: String {
            guard
                let selectedItemId,
                let reaction = reaction(withId: selectedItemId)
            else { return "" }
            return reaction.title
        }

        var lastReactionPosition: Int {
            guard case .loaded(let data) = state else {
                return 0
            }
            return data.reactions.count
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
        await loadSounds()
    }

    func onCreateNewReactionSelected() {
        reactionForEditing = .init(position: 0, title: "")
    }

    func onRemoveReactionSelected(reactionId: String) {
        selectedItemId = reactionId
        alertType = .twoOptionsOneDelete
        showAlert = true
    }

    func onImportAndSendPreExistingReactionsSelected() async {
        await importAndSendPreExistingReactions()
    }

    func onExportReactionsSelected() {
        copyReactionsToClipboard()
    }

    func onEditReactionSelected(reactionId: String) {
        guard let reaction = reaction(withId: reactionId) else { return }
        reactionForEditing = reaction
    }

//    func onMoveReactionUpSelected() {
//        didChangeReactionOrder = true
//        moveUp(selectedID: selectedItem)
//    }
//
//    func onMoveReactionDownSelected() {
//        didChangeReactionOrder = true
//        moveDown(selectedID: selectedItem)
//    }

    func onSendDataSelected() async {
        await sendAll()
    }

    func onSaveReactionSelected() async {
        await loadReactions()
    }

    func onConfirmRemoveReactionSelected() async {
        guard let selectedItemId else {
            alertType = .singleOptionError
            alertTitle = "Nenhuma Reação Selecionada"
            alertMessage = "Selecione uma Reação para remover."
            showAlert = true
            return
        }

        do {
            try await reactionRepository.removeReaction(withId: selectedItemId)
            await loadReactions()
        } catch {
            print(error)
            alertType = .singleOptionError
            alertTitle = "Não Foi Possível Carregar as Reações"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    public func onMoveReaction(from source: IndexSet, to destination: Int) {
        reactions.move(fromOffsets: source, toOffset: destination)
        state = .loaded(ReactionsCRUDModel(reactions: reactions, sounds: sounds))
    }
}

// MARK: - Internal Operations

extension ReactionsCRUDView.ViewModel {

    private func loadReactions() async {
        loadingMessage = "Carregando Reações..."
        isLoading = true

        do {
            let reactions = try await reactionRepository.allReactions()
            self.reactions = reactions
            state = .loaded(ReactionsCRUDModel(reactions: self.reactions, sounds: self.sounds))
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

    private func loadSounds() async {
        loadingMessage = "Carregando Sons..."
        isLoading = true

        do {
            var fetchedSounds = try await allSounds()
            let allAuthors = try await allAuthors()

            guard !fetchedSounds.isEmpty else {
                state = .error("Nenhum som.")
                isLoading = false
                return
            }

            for i in 0...(fetchedSounds.count - 1) {
                fetchedSounds[i].authorName = allAuthors.first(where: { $0.id == fetchedSounds[i].authorId })?.name ?? ""
            }

            fetchedSounds.sort(by: { $0.dateAdded ?? Date() > $1.dateAdded ?? Date() })

            self.sounds = fetchedSounds
            state = .loaded(ReactionsCRUDModel(reactions: self.reactions, sounds: self.sounds))
        } catch {
            print(error)
        }

        isLoading = false
    }

    private func reaction(withId id: String) -> HelperReaction? {
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
            reactions[i].lastUpdate = Date.now.iso8601String
            if let reactionSounds = reactions[i].sounds, !reactionSounds.isEmpty {
                for j in 0...(reactions[i].sounds!.count-1) {
                    reactions[i].sounds![j].dateAdded = Date.now.iso8601String
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

    private func copyReactionsToClipboard() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let jsonData = try encoder.encode(reactions)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(jsonString, forType: .string)
                afterSendingError(title: "Reações Copiadas para a Área de Transferência com Sucesso!")
            }
        } catch {
            afterSendingError(title: "Erro ao Tentar Exportar as Reações", message: error.localizedDescription)
        }
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

// MARK: - Load Sounds Aux

extension ReactionsCRUDView.ViewModel {

    private func allSounds() async throws -> [Sound] {
        let url = URL(string: serverPath + "v3/all-sounds")!
        return try await APIClient().getArray(from: url)
    }

    private func allAuthors() async throws -> [Author] {
        let url = URL(string: serverPath + "v3/all-authors")!
        return try await APIClient().getArray(from: url)
    }
}
