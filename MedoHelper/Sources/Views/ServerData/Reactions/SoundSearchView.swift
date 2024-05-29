//
//  SoundSearchView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 27/05/24.
//

import SwiftUI

struct SoundSearchView: View {

    let addAction: (Sound) -> Void

    @State private var sounds: [Sound] = []

    @State private var searchText = ""
    @State private var selectedItem: Sound.ID?

    // MARK: - Computed Properties

    private var searchResults: [Sound] {
        if searchText.isEmpty {
            return sounds
        } else {
            return sounds.filter { sound in
                return sound.title.contains(searchText.preparedForComparison())
            }
        }
    }

    // MARK: - Environment

    @Environment(\.dismiss) var dismiss

    // MARK: - View Body

    var body: some View {
        VStack {
            TextField("Pesquisar", text: $searchText)

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
                    guard let selectedItemId = selectedItem else { return }
                    print("SELECTED SOUND ID: \(selectedItemId)")
                    guard let sound = sounds.first(where: { $0.id == selectedItemId }) else { return }
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
    }

    // MARK: - Functions

    private func loadSounds() {
        Task {
//            await MainActor.run {
//                showLoadingView = true
//            }

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

//            await MainActor.run {
//                showLoadingView = false
//            }
        }
    }

    private func allSounds() async throws -> [Sound] {
        let url = URL(string: serverPath + "v3/all-sounds")!
        return try await NetworkRabbit.getArray(from: url)
    }

    private func allAuthors() async throws -> [Author] {
        let url = URL(string: serverPath + "v3/all-authors")!
        return try await NetworkRabbit.getArray(from: url)
    }
}

#Preview {
    SoundSearchView(addAction: { _ in })
}
