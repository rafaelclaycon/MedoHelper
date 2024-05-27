//
//  EditReactionView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 01/05/24.
//

import SwiftUI

struct EditReactionView: View {

    @Binding var isBeingShown: Bool

    @State private var editableReactionTitle: String = ""

    // MARK: - Computed Properties

    private var isEditing: Bool {
        return helper.reaction != nil
    }

    private var reactionTitle: String {
        guard let reaction = helper.reaction else { return "" }
        return reaction.title
    }

    private var id: String {
        guard let reaction = helper.reaction else { return "" }
        return "ID: \(reaction.id)"
    }

    private var searchResults: [ReactionSound] {
        guard let reaction = helper.reaction else { return [] }
        guard let sounds = reaction.sounds else { return [] }
        return sounds
    }

    // MARK: - Environment

    @EnvironmentObject var helper: EditReactionHelper

    // MARK: - View Body

    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Text(isEditing ? "Editando Reação \"\(reactionTitle)\"" : "Criando Nova Reação")
                    .font(.title)
                    .bold()

                Spacer()
            }

            HStack {
                Text(id)
                    .foregroundColor(isEditing ? .primary : .gray)

                Spacer()
            }

            TextField("Título do Som", text: $editableReactionTitle)

            Table(searchResults) {
                TableColumn("Posição") { reaction in
                    Text("\(reaction.position)")
                }
                .width(min: 50, max: 50)

                TableColumn("ID do Som", value: \.soundId)

                TableColumn("Data de Adição", value: \.dateAdded)
            }

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
//                    if isEditing {
//                        updateContent()
//                    } else {
//                        createContent()
//                    }
                } label: {
                    Text(isEditing ? "Atualizar" : "Criar")
                        .padding(.horizontal)
                }
                .keyboardShortcut(.defaultAction)
                //.disabled(!hasAllNecessaryData)
            }
        }
        .padding(.all, 26)
        .onAppear {
            editableReactionTitle = reactionTitle
        }
    }
}

#Preview {
    EditReactionView(isBeingShown: .constant(true))
}
