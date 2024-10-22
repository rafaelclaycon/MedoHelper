//
//  NewExternalLinkView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 27/03/24.
//

import SwiftUI

struct NewExternalLinkView: View {

    // MARK: - State Variables

    @State private var externalLink: ExternalLink
    @State private var showRemoveAlert: Bool = false
    @State private var selectedService: MediaService.ID?
    @State private var usualServices: [MediaService] = [.instagram, .pocketCasts, .spotify, .twitch, .youTube]

    // MARK: - Private Variables

    private let isEditing: Bool
    private let saveAction: (ExternalLink) -> Void
    private let removeAction: (ExternalLink) -> Void

    // MARK: - Computed Properties

    private var createButtonIsDisabled: Bool {
        externalLink.symbol == "" || externalLink.title == "" || externalLink.link == ""
    }

    // MARK: - Environment

    @Environment(\.dismiss) var dismiss

    // MARK: - Initializers

    init(
        externalLink: ExternalLink,
        saveAction: @escaping (ExternalLink) -> Void,
        removeAction: @escaping (ExternalLink) -> Void
    ) {
        self.isEditing = externalLink.title != ""
        self.externalLink = externalLink
        self.saveAction = saveAction
        self.removeAction = removeAction

        if externalLink.title == "" {
            self.selectedService = MediaService.youTube.id
            onSelectedServiceChange(newValue: MediaService.youTube.id)
        }
    }

    // MARK: - View Body

    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Text(isEditing ? "Editando \"\(externalLink.title)\"" : "Novo Link Externo")
                    .font(.title)
                    .bold()

                Spacer()
            }

            Picker("Tipo: ", selection: $selectedService) {
                ForEach(usualServices) { service in
                    Text(service.name).tag(Optional(service.id))
                }
                Text("<Personalizado>").tag(nil as Author.ID?)
            }
            .onChange(of: selectedService) { _, newValue in
                onSelectedServiceChange(newValue: newValue)
            }

            if selectedService == nil {
                TextField("Título", text: $externalLink.title)

                TextField("Símbolo", text: $externalLink.symbol)

                TextField("Cor", text: $externalLink.color)
            }

            TextField("URL", text: $externalLink.link)

            Spacer()

            HStack(spacing: 15) {
                if isEditing {
                    Button {
                        showRemoveAlert = true
                    } label: {
                        Text("Remover")
                            .padding(.horizontal)
                    }
                    .alert(isPresented: $showRemoveAlert) {
                        Alert(
                            title: Text("Remover \"\(externalLink.title)\"?"),
                            message: Text(""),
                            primaryButton: .destructive(Text("Remover"), action: {
                                removeAction(externalLink)
                                dismiss()
                            }),
                            secondaryButton: .cancel(Text("Cancelar"))
                        )
                    }
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Cancelar")
                        .padding(.horizontal)
                }
                .keyboardShortcut(.cancelAction)

                Button {
                    saveAction(externalLink)
                    dismiss()
                } label: {
                    Text(isEditing ? "Atualizar" : "Criar")
                        .padding(.horizontal)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(createButtonIsDisabled)
            }
        }
        .padding(.all, 26)
    }

    // MARK: - Functions

    private func onSelectedServiceChange(newValue: String?) {
        if
            let newValue,
            let service = MediaService(id: newValue)
        {
            externalLink.title = service.name
            externalLink.symbol = service.symbol
            externalLink.color = service.color
        } else {
            externalLink.title = ""
            externalLink.symbol = ""
            externalLink.color = ""
        }
    }
}

// MARK: - Internal Data

extension NewExternalLinkView {

    enum MediaService: Identifiable {

        case instagram, pocketCasts, spotify, twitch, youTube

        var id: String {
            self.name
        }

        var name: String {
            switch self {
            case .instagram:
                return "Instagram"
            case .pocketCasts:
                return "Pocket Casts"
            case .spotify:
                return "Spotify"
            case .twitch:
                return "Twitch"
            case .youTube:
                return "YouTube"
            }
        }

        var symbol: String {
            switch self {
            case .instagram:
                return "instagram-orange.png"
            case .pocketCasts:
                return "pocket-casts.png"
            case .spotify:
                return "spotify.png"
            case .twitch:
                return "twitch.png"
            case .youTube:
                return "youtube-full-color.png"
            }
        }

        var color: String {
            switch self {
            case .instagram:
                return "orange"
            case .pocketCasts, .youTube:
                return "red"
            case .spotify:
                return "green"
            case .twitch:
                return "purple"
            }
        }

        init?(id: String) {
            switch id {
            case "Instagram":
                self = .instagram
            case "Pocket Casts":
                self = .pocketCasts
            case "Spotify":
                self = .spotify
            case "Twitch":
                self = .twitch
            case "YouTube":
                self = .youTube
            default:
                return nil
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NewExternalLinkView(
        externalLink: .init(),
        saveAction: { _ in },
        removeAction: { _ in }
    )
}
