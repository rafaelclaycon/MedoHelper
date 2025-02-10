//
//  SoundSearchView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 27/05/24.
//

import SwiftUI

struct SoundSearchView: View {

    let sounds: [Sound]
    let addAction: (Sound) -> Void
    let soundExistsOnReaction: (String) -> Bool

    @State private var searchText = ""
    @State private var selectedItem: Sound.ID?

    // Alert
    @State private var showAlert = false

    // MARK: - Computed Properties

    private var searchResults: [Sound] {
        if searchText.isEmpty {
            return sounds
        } else {
            return sounds.filter { sound in
                let searchString = "\(sound.title.preparedForComparison()) \(sound.authorName?.preparedForComparison() ?? "")"
                return searchString
                    .contains(searchText.preparedForComparison())
            }
        }
    }

    // MARK: - Environment

    @Environment(\.dismiss) var dismiss

    // MARK: - View Body

    var body: some View {
        VStack {
            HStack {
                Spacer()

                TextField("Pesquisar", text: $searchText)
                    .frame(width: 300)
            }

            Table(searchResults, selection: $selectedItem) {
                TableColumn("Título", value: \.title)

                TableColumn("Autor") { sound in
                    guard let authorName = sound.authorName else { return Text("") }
                    return Text(authorName)
                }
            }
            //.searchable(text: $searchText) - Bug não abre mais a sheet. Abrir Feedback.

            HStack(spacing: 15) {
                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Cancelar")
                        .padding(.horizontal)
                }
                .keyboardShortcut(.cancelAction)

                Button {
                    guard
                        let selectedItem,
                        let sound = sounds.first(where: { $0.id == selectedItem })
                    else { return }

                    guard !soundExistsOnReaction(sound.id) else {
                        showAlert = true
                        return
                    }

                    addAction(sound)
                    dismiss()
                } label: {
                    Text("Adicionar")
                        .padding(.horizontal)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedItem == nil)
            }
        }
        .padding(.all, 26)
        .alert(
            "O Som Selecionado Já Existe na Reação",
            isPresented: $showAlert,
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: { Text("Não é permitido ter o mesmo som 2 vezes na mesma Reação. Selecione outro som.") }
        )
    }
}

// MARK: - Preview

#Preview {
    SoundSearchView(
        sounds: [.init(title: "Teste")],
        addAction: { _ in },
        soundExistsOnReaction: { _ in
            return false
        }
    )
}
