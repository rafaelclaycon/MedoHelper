//
//  SoundSearchView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 27/05/24.
//

import SwiftUI

struct SoundSearchView: View {

    let addAction: (Sound) -> Void
    let soundExistsOnReaction: (String) -> Bool

    @State private var sounds: [Sound] = []

    @State private var searchText = ""
    @State private var selectedItem: Sound.ID?
    @State private var isLoading: Bool = false

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
            Table(searchResults, selection: $selectedItem) {
                TableColumn("Título", value: \.title)

                TableColumn("Autor") { sound in
                    guard let authorName = sound.authorName else { return Text("") }
                    return Text(authorName)
                }
            }
            .searchable(text: $searchText)

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
        .onAppear {
            loadSounds()
        }
        .overlay {
            if isLoading {
                LoadingView(message: "Carregando sons...")
            }
        }
        .alert(
            "O Som Selecionado Já Existe na Reação",
            isPresented: $showAlert,
            actions: {
                Button("OK", role: .cancel) {}
            },
            message: { Text("Não é permitido ter o mesmo som 2 vezes na mesma Reação. Selecione outro som.") }
        )
    }

    // MARK: - Functions

    private func loadSounds() {
        Task {
            isLoading = true

            do {
                var fetchedSounds = try await allSounds()
                let allAuthors = try await allAuthors()

                for i in 0...(fetchedSounds.count - 1) {
                    fetchedSounds[i].authorName = allAuthors.first(where: { $0.id == fetchedSounds[i].authorId })?.name ?? ""
                }

                fetchedSounds.sort(by: { $0.dateAdded ?? Date() > $1.dateAdded ?? Date() })

                self.sounds = fetchedSounds
            } catch {
                print(error)
            }

            isLoading = false
        }
    }

    private func allSounds() async throws -> [Sound] {
        let url = URL(string: serverPath + "v3/all-sounds")!
        return try await APIClient().getArray(from: url)
    }

    private func allAuthors() async throws -> [Author] {
        let url = URL(string: serverPath + "v3/all-authors")!
        return try await APIClient().getArray(from: url)
    }
}

// MARK: - Preview

#Preview {
    SoundSearchView(
        addAction: { _ in },
        soundExistsOnReaction: { _ in
            return false
        }
    )
}
