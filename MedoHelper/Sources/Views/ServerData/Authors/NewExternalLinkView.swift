//
//  NewExternalLinkView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 27/03/24.
//

import SwiftUI

struct NewExternalLinkView: View {

    // MARK: - State Variables

    @Binding var isBeingShown: Bool
    @State var externalLink: ExternalLink

    // MARK: - Private Variables

    private let isEditing: Bool
    private let saveAction: (ExternalLink) -> Void

    // MARK: - Computed Properties

    private var createButtonIsDisabled: Bool {
        externalLink.symbol == "" || externalLink.title == "" || externalLink.link == ""
    }

    // MARK: - Initializers

    init(
        isBeingShown: Binding<Bool>,
        externalLink: ExternalLink? = nil,
        saveAction: @escaping (ExternalLink) -> Void
    ) {
        _isBeingShown = isBeingShown
        self.isEditing = externalLink != nil
        self.saveAction = saveAction
        self.externalLink = externalLink ?? ExternalLink()
    }

    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Text(isEditing ? "Editando \"\(externalLink.title)\"" : "Novo Link Externo")
                    .font(.title)
                    .bold()

                Spacer()
            }

            TextField("Título", text: $externalLink.title)

            TextField("Símbolo", text: $externalLink.symbol)

            TextField("Cor", text: $externalLink.color)

            TextField("URL", text: $externalLink.link)

            Spacer()

            HStack(spacing: 15) {
                Spacer()

                Button {
                    isBeingShown = false
                } label: {
                    Text("Cancelar")
                        .padding(.horizontal)
                }
                .keyboardShortcut(.cancelAction)

                Button {
                    saveAction(externalLink)
                    isBeingShown = false
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
}

#Preview {
    NewExternalLinkView(
        isBeingShown: .constant(true),
        saveAction: { _ in }
    )
}
