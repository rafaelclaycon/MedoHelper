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
        externalLink: ExternalLink?,
        saveAction: @escaping (ExternalLink) -> Void,
        removeAction: @escaping (ExternalLink) -> Void
    ) {
        self.isEditing = externalLink != nil
        self.externalLink = externalLink ?? ExternalLink()
        self.saveAction = saveAction
        self.removeAction = removeAction
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
}

#Preview {
    NewExternalLinkView(
        externalLink: nil,
        saveAction: { _ in },
        removeAction: { _ in }
    )
}
