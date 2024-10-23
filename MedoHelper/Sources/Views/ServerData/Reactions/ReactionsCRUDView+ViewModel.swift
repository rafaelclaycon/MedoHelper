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
        @Published var showLoadingView: Bool = false

        @Published var reactionForEditing: ReactionDTO?

        @Published var didChangeReactionOrder: Bool = false

        // Progress View
        @Published var showSendProgress = false
        @Published var progressAmount = 0.0
        @Published var totalAmount = 2.0
        @Published var modalMessage = ""

        // Alert
        @Published var showAlert = false
        @Published var alertType: AlertType = .singleOptionInformative
        @Published var alertErrorMessage: String = ""

        // MARK: - Stored Properties

        private let apiClient: APIClientProtocol

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

        // MARK: - Initializer

        init(
            apiClient: APIClientProtocol
        ) {
            self.apiClient = apiClient
        }
    }
}

// MARK: - User actions

extension ReactionsCRUDView.ViewModel {

    func onViewAppear() {
        loadReactions()
    }

    func onCreateNewReactionSelected() {
        reactionForEditing = .init(position: 0, title: "")
    }

    func onRemoveReactionSelected() {
        alertType = .twoOptionsOneDelete
        showAlert = true
    }

    func onImportAndSendPreExistingReactionsSelected() {
        importAndSendPreExistingReactions()
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

    func onSendDataSelected() {

    }

    func onSaveReactionSelected(reaction: ReactionDTO) {
        if let index = reactions.firstIndex(where: { $0.id == reaction.id }) {
            reactions[index] = reaction
        } else {
            reactions.append(reaction)
        }
    }
}

// MARK: - Internal Functions

extension ReactionsCRUDView.ViewModel {

    private func loadReactions() {
        Task {
            await MainActor.run {
                showLoadingView = true
            }

            do {
                let url = URL(string: serverPath + "v4/reactions")!

                let serverReactions: [AppReaction] = try await apiClient.getArray(from: url)
                var dtos = serverReactions.map { ReactionDTO(appReaction: $0) }
                dtos.sort(by: { $0.position < $1.position })

                guard !dtos.isEmpty else {
                    await MainActor.run {
                        showLoadingView = false
                    }
                    return
                }

                for i in 0...(dtos.count - 1) {
                    let reactionUrl = URL(string: serverPath + "v4/reaction/\(dtos[i].id)")!
                    dtos[i].sounds = try await apiClient.getArray(from: reactionUrl)
                }

                self.reactions = dtos
            } catch {
                print(error)
            }

            await MainActor.run {
                showLoadingView = false
            }
        }
    }

    private func reaction(withId id: String) -> ReactionDTO? {
        for reaction in reactions {
            if reaction.id == id {
                return reaction
            }
        }
        return nil
    }

    private func importAndSendPreExistingReactions() {
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

        sendAll()
    }

    private func sendAll() {
        Task {
            totalAmount = Double(reactions.count)
            showSendProgress = true
            modalMessage = "Enviando Dados..."
            progressAmount = 0

            do {
                let reactionsUrl = URL(string: serverPath + "v4/delete-all-reactions/\(reactionsPassword)")!
                let soundsUrl = URL(string: serverPath + "v4/delete-all-reaction-sounds/\(reactionsPassword)")!
                print(reactionsUrl.absoluteString)
                print(soundsUrl.absoluteString)
                guard try await apiClient.delete(in: reactionsUrl) else {
                    print("Não foi possível apagar as Reações.")
                    return
                }
                guard try await apiClient.delete(in: soundsUrl) else {
                    print("Não foi possível apagar os sons das Reações.")
                    return
                }

                print("Reactions count: \(reactions.count)")
                for reaction in reactions {
                    try await send(reaction: AppReaction(dto: reaction))

                    if let sounds = reaction.sounds {
                        let dtos = sounds.map { ReactionSoundDTO(reactionSound: $0, reactionId: reaction.id) }
                        try await send(reactionSounds: dtos)
                    }

                    progressAmount += 1
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
                    self.showSendProgress = false
                }
            } catch {
                print(error)
//                alertType = .singleOptionInformative
//                alertTitle = "Falha ao Criar o Som"
//                alertMessage = error.localizedDescription
                showSendProgress = false
                // return showingAlert = true
            }
        }
    }

    private func send(reaction: AppReaction) async throws {
        let url = URL(string: serverPath + "v4/create-reaction/\(reactionsPassword)")!
        let _ = try await apiClient.post(data: reaction, to: url)
    }

    private func send(reactionSounds: [ReactionSoundDTO]) async throws {
        let url = URL(string: serverPath + "v4/add-sounds-to-reaction/\(reactionsPassword)")!
        let _ = try await apiClient.post(data: reactionSounds, to: url)
    }

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
