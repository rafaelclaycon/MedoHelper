//
//  DynamicBannerView+ViewModel.swift
//  MedoHelper
//
//  Created by Claude on 25/10/26.
//

import SwiftUI
import AppKit

extension DynamicBannerView {

    /// The banner as it's being edited. Rows carry their own ids so editing a paragraph
    /// or a button title doesn't reshuffle the list.
    struct Draft: Equatable {

        struct Paragraph: Identifiable, Equatable {
            let id = UUID()
            var text: String
        }

        struct Button: Identifiable, Equatable {
            let id = UUID()
            var title: String
            var type: DynamicBannerButtonType
            var data: String
            var additionalData: String
        }

        var symbol: String = ""
        var title: String = ""
        var paragraphs: [Paragraph] = []
        var buttons: [Button] = []

        init() {}

        init(_ banner: DynamicBannerData) {
            symbol = banner.symbol
            title = banner.title
            paragraphs = banner.text.map { Paragraph(text: $0) }
            buttons = banner.buttons.map {
                Button(title: $0.title, type: $0.type, data: $0.data, additionalData: $0.additionalData ?? "")
            }
        }

        /// What gets published. Trims everything and drops empty paragraphs; links have
        /// no toast, so they never carry `additionalData`.
        var banner: DynamicBannerData {
            DynamicBannerData(
                symbol: symbol.trimmed,
                title: title.trimmed,
                text: paragraphs.map(\.text.trimmed).filter { !$0.isEmpty },
                buttons: buttons.map { button in
                    let toast = button.additionalData.trimmed
                    return DynamicBannerButton(
                        title: button.title.trimmed,
                        type: button.type,
                        data: button.data.trimmed,
                        additionalData: button.type == .copyText && !toast.isEmpty ? toast : nil
                    )
                }
            )
        }
    }

    @MainActor
    final class ViewModel: ObservableObject {

        @Published var draft = Draft()
        /// What's on the server now. Nil while loading, or when there's no banner in the
        /// app because none was ever set or it was removed.
        @Published var published: DynamicBannerData?
        @Published var isLoading: Bool = true
        /// False until the server answered once. Without it, a failed load would leave an
        /// empty draft that could be published over the real banner.
        @Published var hasLoaded: Bool = false
        @Published var isPublishing: Bool = false
        @Published var showPublishConfirmation: Bool = false
        @Published var isRemoving: Bool = false
        @Published var showRemoveConfirmation: Bool = false

        @Published var alertTitle: String = ""
        @Published var alertMessage: String = ""
        @Published var showAlert: Bool = false

        private let repository: DynamicBannerRepositoryProtocol

        init(repository: DynamicBannerRepositoryProtocol = DynamicBannerRepository()) {
            self.repository = repository
        }

        var hasUnpublishedChanges: Bool {
            hasLoaded && !isLoading && draft.banner != published
        }

        /// Things that would break the banner in the app. Publishing waits until it's empty.
        var problems: [String] {
            let banner = draft.banner
            var problems: [String] = []
            if banner.symbol.isEmpty {
                problems.append("Falta o símbolo.")
            }
            if banner.title.isEmpty {
                problems.append("Falta o título.")
            }
            for (index, button) in banner.buttons.enumerated() {
                let name = "Botão \(index + 1)"
                if button.title.isEmpty {
                    problems.append("\(name): falta o título.")
                }
                if button.data.isEmpty {
                    problems.append("\(name): falta \(button.type == .copyText ? "o texto a copiar" : "o link").")
                } else if button.type == .openLink, !Self.isWebLink(button.data) {
                    problems.append("\(name): o link precisa começar com https://.")
                }
            }
            // The app identifies buttons by title and paragraphs by their text.
            if Set(banner.buttons.map(\.title)).count < banner.buttons.count {
                problems.append("Dois botões têm o mesmo título; o app mostraria só um.")
            }
            if Set(banner.text).count < banner.text.count {
                problems.append("Dois parágrafos são iguais; o app mostraria só um.")
            }
            for (index, paragraph) in banner.text.enumerated() where (try? AttributedString(markdown: paragraph)) == nil {
                problems.append("Parágrafo \(index + 1): o Markdown não é válido, o app mostraria vazio.")
            }
            return problems
        }

        /// SF Symbols come and go between OS versions, so a name missing on this Mac
        /// might still exist on iOS. Worth a look, not a block.
        var symbolIsUnknownHere: Bool {
            let symbol = draft.symbol.trimmed
            return !symbol.isEmpty && NSImage(systemSymbolName: symbol, accessibilityDescription: nil) == nil
        }

        var canPublish: Bool {
            hasUnpublishedChanges && problems.isEmpty && !isPublishing && !isRemoving
        }

        var canRemove: Bool {
            hasLoaded && published != nil && !isPublishing && !isRemoving
        }

        var publishedJSON: String {
            (try? DynamicBannerRepository.encoded(draft.banner)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
        }

        private static func isWebLink(_ text: String) -> Bool {
            guard let url = URL(string: text), let scheme = url.scheme?.lowercased() else { return false }
            return (scheme == "https" || scheme == "http") && url.host != nil
        }
    }
}

// MARK: - User Actions

extension DynamicBannerView.ViewModel {

    func onViewAppear() async {
        // Keep edits when coming back from another tab.
        guard !hasLoaded else { return }
        await load()
    }

    func onReloadSelected() async {
        await load()
    }

    func onDiscardChangesSelected() {
        draft = published.map(DynamicBannerView.Draft.init) ?? DynamicBannerView.Draft()
    }

    func onAddParagraph() {
        draft.paragraphs.append(.init(text: ""))
    }

    func onAddButton() {
        draft.buttons.append(.init(title: "", type: .openLink, data: "", additionalData: ""))
    }

    func onPublishSelected() {
        guard canPublish else { return }
        showPublishConfirmation = true
    }

    func onRemoveSelected() {
        guard canRemove else { return }
        showRemoveConfirmation = true
    }

    /// Keeps the draft, so putting the same banner back is one publish away.
    func onRemoveConfirmed() async {
        isRemoving = true
        defer { isRemoving = false }
        do {
            try await repository.removeBanner()
            published = nil
        } catch {
            print(error)
            showAlert(title: "Não foi possível remover", message: error.localizedDescription)
        }
    }

    func onPublishConfirmed() async {
        isPublishing = true
        defer { isPublishing = false }
        let banner = draft.banner
        do {
            try await repository.setBanner(banner)
            published = banner
            draft = DynamicBannerView.Draft(banner)
        } catch {
            print(error)
            showAlert(title: "Não foi possível publicar", message: error.localizedDescription)
        }
    }
}

// MARK: - Internal Operations

extension DynamicBannerView.ViewModel {

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            published = try await repository.banner()
            draft = published.map(DynamicBannerView.Draft.init) ?? DynamicBannerView.Draft()
            hasLoaded = true
        } catch {
            print(error)
            showAlert(title: "Não foi possível carregar o banner", message: error.localizedDescription)
        }
    }

    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

private extension String {

    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
