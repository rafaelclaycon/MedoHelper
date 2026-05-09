//
//  SoundRequestsView+ViewModel.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 19/04/26.
//

import SwiftUI

extension SoundRequestsView {

    @MainActor
    final class ViewModel: ObservableObject {

        @Published var state: LoadingState<[SoundRequest]> = .loading
        @Published var requests: [SoundRequest] = []
        @Published var selectedRequestId: String?
        @Published var showingNewRequestSheet: Bool = false

        @Published var alertTitle: String = ""
        @Published var alertMessage: String = ""
        @Published var showAlert: Bool = false

        private let repository: SoundRequestsRepositoryProtocol

        init(repository: SoundRequestsRepositoryProtocol = JSONSoundRequestsRepository()) {
            self.repository = repository
        }

        var selectedRequest: SoundRequest? {
            guard let selectedRequestId else { return nil }
            return requests.first { $0.id == selectedRequestId }
        }
    }
}

// MARK: - User Actions

extension SoundRequestsView.ViewModel {

    func onViewAppear() async {
        await loadAll()
    }

    func onReloadSelected() async {
        await loadAll()
    }

    func onCreateRequestSelected() {
        showingNewRequestSheet = true
    }

    func onConfirmCreate(title: String, requesterName: String, emailReceivedAt: Date) async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedName = requesterName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, !trimmedName.isEmpty else { return }

        let new = SoundRequest(
            title: trimmedTitle,
            requesterName: trimmedName,
            emailReceivedAt: emailReceivedAt
        )

        do {
            try await repository.add(new)
        } catch SoundRequestsRepositoryError.notImplemented {
            // Fall back to the in-memory list.
        } catch {
            showError("Erro ao Adicionar Pedido", message: error.localizedDescription)
            return
        }

        requests.insert(new, at: 0)
        sortRequests()
        state = .loaded(requests)
        showingNewRequestSheet = false
    }

    func onToggleStatus(id: String) async {
        guard let index = requests.firstIndex(where: { $0.id == id }) else { return }

        var updated = requests[index]
        switch updated.status {
        case .unfulfilled:
            updated.status = .fulfilled
            updated.fulfilledAt = .now
        case .fulfilled:
            updated.status = .unfulfilled
            updated.fulfilledAt = nil
        }

        do {
            try await repository.update(updated)
        } catch SoundRequestsRepositoryError.notImplemented {
            // Fall back to the in-memory list.
        } catch {
            showError("Erro ao Atualizar Pedido", message: error.localizedDescription)
            return
        }

        requests[index] = updated
        sortRequests()
        state = .loaded(requests)
    }

    func onRemoveSelected(id: String) async {
        do {
            try await repository.remove(withId: id)
        } catch SoundRequestsRepositoryError.notImplemented {
            // Fall back to the in-memory list.
        } catch {
            showError("Erro ao Remover Pedido", message: error.localizedDescription)
            return
        }

        requests.removeAll { $0.id == id }
        if selectedRequestId == id {
            selectedRequestId = nil
        }
        state = .loaded(requests)
    }
}

// MARK: - Internal Operations

extension SoundRequestsView.ViewModel {

    private func loadAll() async {
        state = .loading

        do {
            let fetched = try await repository.allRequests()
            requests = fetched
            sortRequests()
            state = .loaded(requests)
        } catch SoundRequestsRepositoryError.notImplemented {
            // Keep whatever is in memory so the UI remains usable while
            // the backend endpoint is not available yet.
            sortRequests()
            state = .loaded(requests)
        } catch {
            print(error)
            state = .error(error.localizedDescription)
        }
    }

    private func sortRequests() {
        requests.sort { lhs, rhs in
            if lhs.status != rhs.status {
                return lhs.status == .unfulfilled
            }
            return lhs.emailReceivedAt > rhs.emailReceivedAt
        }
    }

    private func showError(_ title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
