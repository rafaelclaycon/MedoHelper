//
//  FolderResearchView+ViewModel.swift
//  MedoHelper
//
//  Created by Claude on 21/08/26.
//

import SwiftUI

extension FolderResearchView {

    enum SortOption: String, CaseIterable, Identifiable {
        case folderCount
        case lastActivity

        var id: String { rawValue }

        var label: String {
            switch self {
            case .folderCount: return "Nº de pastas"
            case .lastActivity: return "Última atividade"
            }
        }
    }

    @MainActor
    final class ViewModel: ObservableObject {

        static let allDevicesFilter = "Todos"

        @Published var state: LoadingState<FolderResearchAnalyticsResponse> = .loading
        @Published var searchText: String = ""
        @Published var sortOption: SortOption = .folderCount
        @Published var deviceModelFilter: String = ViewModel.allDevicesFilter
        @Published var expandedUserIDs: Set<String> = []
        @Published var expandedFolderID: String?

        private var hasLoadedOnce = false
        private let repository: AnalyticsRepositoryProtocol

        init(repository: AnalyticsRepositoryProtocol = AnalyticsRepository()) {
            self.repository = repository
        }

        var response: FolderResearchAnalyticsResponse? {
            if case .loaded(let response) = state { return response }
            return nil
        }

        var availableDeviceModels: [String] {
            guard let response else { return [] }
            let names = response.users.flatMap { $0.devices.map(\.modelName) }
            return [Self.allDevicesFilter] + Set(names).sorted()
        }

        var filteredUsers: [FolderResearchUser] {
            guard let response else { return [] }
            var users = response.users

            if deviceModelFilter != Self.allDevicesFilter {
                users = users.filter { user in
                    user.devices.contains { $0.modelName == deviceModelFilter }
                }
            }

            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !query.isEmpty {
                users = users.filter { user in
                    user.folders.contains { folder in
                        folder.name.localizedCaseInsensitiveContains(query) ||
                        folder.contents.contains { $0.title.localizedCaseInsensitiveContains(query) }
                    }
                }
            }

            switch sortOption {
            case .folderCount:
                users.sort { $0.folderCount > $1.folderCount }
            case .lastActivity:
                users.sort { ($0.lastActivityDate ?? .distantPast) > ($1.lastActivityDate ?? .distantPast) }
            }
            return users
        }

        func onViewAppear() async {
            guard !hasLoadedOnce else { return }
            await load()
        }

        func onRetry() async {
            await load()
        }

        func toggleUserExpanded(_ id: String) {
            if expandedUserIDs.contains(id) {
                expandedUserIDs.remove(id)
            } else {
                expandedUserIDs.insert(id)
            }
        }

        func toggleFolderExpanded(_ id: String) {
            expandedFolderID = (expandedFolderID == id) ? nil : id
        }

        private func load() async {
            state = .loading
            do {
                let response = try await repository.fetchFolderResearchAnalytics()
                state = .loaded(response)
                hasLoadedOnce = true
            } catch {
                print(error)
                state = .error(error.localizedDescription)
            }
        }
    }
}
