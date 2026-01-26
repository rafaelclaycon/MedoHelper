//
//  ServerMusicGenreCRUDView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 26/08/23.
//

import SwiftUI

struct ServerMusicGenreCRUDView: View {

    @State private var genre: MusicGenre? = nil

    @State private var showAddAlreadyOnAppSheet = false
    @State private var fixedData: [MusicGenre] = Bundle.main.decodeJSON("musicGenre_data.json")

    @State private var genres: [MusicGenre] = []
    @State private var selectedItem: MusicGenre.ID?

    @State private var showLoadingView = false
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var searchText = ""

    private var selectedAuthorName: String {
        guard let selectedItem else { return "" }
        guard let genre = getMusicGenre(withID: selectedItem, from: genres) else { return "" }
        return genre.name
    }

    private var searchResults: [MusicGenre] {
        if searchText.isEmpty {
            return genres
        } else {
            return genres.filter { genre in
                let normalizedGenreName = genre.name.preparedForComparison()
                return normalizedGenreName.contains(searchText.preparedForComparison())
            }
        }
    }

    var body: some View {
        ZStack {
            VStack {
                Table(searchResults, selection: $selectedItem) {
                    TableColumn("Sím.", value: \.symbol).width(min: 30, max: 30)
                    TableColumn("Nome", value: \.name)
                }.contextMenu(forSelectionType: MusicGenre.ID.self) { items in
                    Section {
                        Button("Editar Som") {
                            //                        guard let selectedItemId = items.first else { return }
                            //                        editAuthor(withId: selectedItemId)
                        }
                    }

                    Section {
                        Button("Remover Som") {
                            //                        guard let selectedItemId = items.first else { return }
                            //                        selectedSound = selectedItemId
                            //                        alertType = .twoOptionsOneDelete
                            //                        showAlert = true
                        }
                    }
                } primaryAction: { items in
                    //guard let selectedItemId = items.first else { return }
                    //editAuthor(withId: selectedItemId)
                }
                .searchable(text: $searchText)

                HStack(spacing: 10) {
                    Button {
                        self.genre = nil
                        showEditSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .sheet(isPresented: $showEditSheet) {
                        EditMusicGenreOnServerView(isBeingShown: $showEditSheet, genre: genre)
                            .frame(minWidth: 800, minHeight: 500)
                    }
                    .disabled(genres.count == 0)

                    Button {
                        print((selectedItem ?? "") as String)
                        //showDeleteAlert = true
                    } label: {
                        Image(systemName: "minus")
                    }
                    //                .alert(isPresented: $showDeleteAlert) {
                    //                    Alert(title: Text("Remover \"\(selectedAuthorName)\""), message: Text("Tem certeza de que deseja remover o(a) autor(a) \"\(selectedAuthorName)\"? A mudança será sincronizada com o servidor e propagada para todos os clientes na próxima sincronização."), primaryButton: .destructive(Text("Remover"), action: {
                    //                        guard let selectedItem = selectedItem else { return }
                    //                        removeAuthor(withId: selectedItem)
                    //                    }), secondaryButton: .cancel(Text("Cancelar")))
                    //                }
                    .disabled(genres.count == 0)

                    Spacer()

                    Button("Enviar Gêneros Musicais Já no App") {
                        fixedData.sort(by: { $0.name.preparedForComparison() < $1.name.preparedForComparison() })
                        showAddAlreadyOnAppSheet = true
                    }
                    .sheet(isPresented: $showAddAlreadyOnAppSheet) {
                        MoveDataToServerView(isBeingShown: $showAddAlreadyOnAppSheet,
                                             data: fixedData,
                                             chunkSize: 100,
                                             endpointEnding: "v3/import-music-genres/\(Secrets.assetOperationPassword)")
                        .frame(minWidth: 800, minHeight: 500)
                    }
                    .padding(.trailing, 10)
                    .disabled(genres.count > 0)

                    Text("\(genres.count.formattedString) itens")
                }
            }
            .navigationTitle("Gêneros Musicais no Servidor")
            .padding()
            .onAppear {
                fetchItems()
            }
            .onChange(of: showAddAlreadyOnAppSheet) { if !$0 { fetchItems() } }
            .onChange(of: showEditSheet) { if !$0 { fetchItems() } }

            if showLoadingView {
                LoadingView()
            }
        }
    }

    func fetchItems() {
        Task {
            await MainActor.run {
                showLoadingView = true
            }

            do {
                let url = URL(string: serverPath + "v3/all-music-genres")!

                var fetchedItems: [MusicGenre] = try await APIClient().getArray(from: url)

                fetchedItems.sort(by: { $0.name.preparedForComparison() < $1.name.preparedForComparison() })

                self.genres = fetchedItems
            } catch {
                print(error)
            }

            await MainActor.run {
                showLoadingView = false
            }
        }
    }

    private func getMusicGenre(withID id: String, from genres: [MusicGenre]) -> MusicGenre? {
        for genre in genres {
            if genre.id == id {
                return genre
            }
        }
        return nil
    }
}

struct ServerMusicGenreCRUDView_Previews: PreviewProvider {

    static var previews: some View {
        ServerMusicGenreCRUDView()
    }
}
