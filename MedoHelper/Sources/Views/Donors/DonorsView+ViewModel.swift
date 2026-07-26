//
//  DonorsView+ViewModel.swift
//  MedoHelper
//
//  Created by Claude on 03/07/26.
//

import SwiftUI

extension DonorsView {

    enum SortOrder: String, CaseIterable, Identifiable {
        case nameAscending
        case newestFirst
        case oldestFirst

        var id: String { rawValue }

        var label: String {
            switch self {
            case .nameAscending: return "Nome (A–Z)"
            case .newestFirst: return "Adicionado (mais recente)"
            case .oldestFirst: return "Adicionado (mais antigo)"
            }
        }
    }

    @MainActor
    final class ViewModel: ObservableObject {

        @Published var state: LoadingState<[Donor]> = .loading
        @Published var donors: [Donor] = []
        @Published var selection: Set<Donor.ID> = []

        @Published var sortOrder: SortOrder = .nameAscending {
            didSet { applySort() }
        }

        // Quick-add draft. Tier + history are kept between adds so several
        // people of the same kind can be entered in a row without re-toggling.
        @Published var draftName: String = ""
        @Published var draftRecurrence: DonorRecurrence = .none
        @Published var draftHasDonatedBefore: Bool = false

        /// True when the local list has edits not yet pushed via `set-donor-names`.
        @Published var hasUnsentChanges: Bool = false
        @Published var isPublishing: Bool = false

        @Published var alertTitle: String = ""
        @Published var alertMessage: String = ""
        @Published var showAlert: Bool = false

        private let repository: DonorsRepositoryProtocol
        private let store: DonorsLocalStore

        init(
            repository: DonorsRepositoryProtocol = DonorsRepository(),
            store: DonorsLocalStore = DonorsLocalStore()
        ) {
            self.repository = repository
            self.store = store
        }
    }
}

// MARK: - User Actions

extension DonorsView.ViewModel {

    func onViewAppear() async {
        // Only pull from the server on the first appearance; keep local edits
        // afterwards so switching tabs doesn't discard unsent work.
        guard donors.isEmpty else { return }
        await loadFromServer()
    }

    func onReloadSelected() async {
        if hasUnsentChanges {
            // Reloading overwrites the working list with the server's; warn first.
            showAlert(
                title: "Alterações não enviadas",
                message: "Você tem alterações que ainda não foram enviadas ao servidor. Recarregar vai descartá-las. Se quiser mantê-las, use \"Enviar ao Servidor\" antes de recarregar."
            )
        }
        await loadFromServer()
    }

    func onAddDonor() {
        let name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        if donors.contains(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            showAlert(title: "Nome duplicado", message: "\"\(name)\" já está na lista.")
            return
        }

        let donor = Donor(
            name: name,
            hasDonatedBefore: draftHasDonatedBefore,
            recurrence: draftRecurrence
        )
        donors.append(donor)
        draftName = ""
        markChangedAndPersist()
        applySort()
    }

    func onRemoveSelected() {
        guard !selection.isEmpty else { return }
        donors.removeAll { selection.contains($0.id) }
        selection.removeAll()
        markChangedAndPersist()
        state = .loaded(donors)
    }

    func onRemove(id: Donor.ID) {
        donors.removeAll { $0.id == id }
        selection.remove(id)
        markChangedAndPersist()
        state = .loaded(donors)
    }

    func setHasDonatedBefore(_ value: Bool, for id: Donor.ID) {
        guard let index = donors.firstIndex(where: { $0.id == id }) else { return }
        donors[index].hasDonatedBefore = value
        markChangedAndPersist()
        state = .loaded(donors)
    }

    func setRecurrence(_ value: DonorRecurrence, for id: Donor.ID) {
        guard let index = donors.firstIndex(where: { $0.id == id }) else { return }
        donors[index].recurrence = value
        markChangedAndPersist()
        state = .loaded(donors)
    }

    func onPublish() async {
        isPublishing = true
        defer { isPublishing = false }
        do {
            try await repository.setDonors(donors.map(\.dto))
            hasUnsentChanges = false
            store.save(donors)
            showAlert(
                title: "Enviado",
                message: "\(donors.count) doador(es) enviado(s) ao servidor com sucesso."
            )
        } catch {
            print(error)
            showAlert(title: "Erro ao Enviar", message: error.localizedDescription)
        }
    }
}

// MARK: - Internal Operations

extension DonorsView.ViewModel {

    private func loadFromServer() async {
        state = .loading
        let local = store.load()
        do {
            let serverDonors = try await repository.serverDonors()
            // Keep the locally-remembered add-date (and id) whenever a server
            // donor matches one we already know by name.
            donors = serverDonors.map { dto in
                if let match = local.first(where: { $0.name.caseInsensitiveCompare(dto.name) == .orderedSame }) {
                    return Donor(dto: dto, id: match.id, createdAt: match.createdAt)
                }
                return Donor(dto: dto)
            }
            store.save(donors)
            hasUnsentChanges = false
            applySort()
        } catch {
            print(error)
            if local.isEmpty {
                state = .error(error.localizedDescription)
            } else {
                // Server unreachable but we have a local copy — stay usable.
                donors = local
                applySort()
                showAlert(
                    title: "Sem conexão com o servidor",
                    message: "Mostrando a lista local salva. Erro: \(error.localizedDescription)"
                )
            }
        }
    }

    private func applySort() {
        switch sortOrder {
        case .nameAscending:
            donors.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .newestFirst:
            donors.sort { $0.createdAt > $1.createdAt }
        case .oldestFirst:
            donors.sort { $0.createdAt < $1.createdAt }
        }
        state = .loaded(donors)
    }

    private func markChangedAndPersist() {
        hasUnsentChanges = true
        store.save(donors)
    }

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
