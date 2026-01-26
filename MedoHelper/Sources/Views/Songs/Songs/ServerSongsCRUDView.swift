//
//  ServerSongsCRUDView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 23/05/23.
//

import SwiftUI

struct ServerSongsCRUDView: View {
    
    @State private var song: Song? = nil
    @State private var items: [Song] = []
    @State private var selectedItem: Sound.ID?
    
    @State private var showLoadingView = false
    @State private var showAddAlreadyOnAppSheet = false
    @State private var fixedData: [Song]? = nil
    @State private var showEditSheet = false
    @State private var showAlert = false
    @State private var alertType: AlertType = .singleOptionInformative
    @State private var alertErrorMessage: String = ""
    @State private var showReplaceSheet = false
    @State private var searchText = ""
    
    private var selectedSongTitle: String {
//        guard let selectedSound = selectedSound else { return "" }
//        guard let sound = getSound(withID: selectedSound, from: sounds) else { return "" }
//        return sound.title
        return ""
    }

    private var searchResults: [Song] {
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { item in
                let normalizedSongTitle = item.title.preparedForComparison()
                return normalizedSongTitle.contains(searchText.preparedForComparison())
            }
        }
    }

    var body: some View {
        ZStack {
            VStack {
                Table(searchResults, selection: $selectedItem) {
                    TableColumn("Título", value: \.title)
                    
                    TableColumn("Gênero", value: \.genreId)
                        .width(min: 50, max: 100)
                    
                    TableColumn("Adicionado em") { song in
                        Text(song.dateAdded?.displayString ?? "")
                    }
                    .width(min: 50, max: 100)
                    
                    TableColumn("Duração") { song in
                        Text("\(song.duration.asString())")
                    }
                    .width(min: 50, max: 100)
                }.contextMenu(forSelectionType: Song.ID.self) { items in
                    Section {
                        Button("Editar Metadados da Música") {
                            guard let selectedItemId = items.first else { return }
                            editSong(withId: selectedItemId)
                        }

                        Button("Substituir Arquivo da Música") {
                            guard let selectedItemId = items.first else { return }
                            replaceSongFile(withId: selectedItemId)
                        }
                    }
                    
                    Section {
                        Button("Remover Música") {
                            guard let selectedItemId = items.first else { return }
                            selectedItem = selectedItemId
                            alertType = .twoOptionsOneDelete
                            showAlert = true
                        }
                    }
                } primaryAction: { items in
                    guard let selectedItemId = items.first else { return }
                    editSong(withId: selectedItemId)
                }
                .searchable(text: $searchText)
                
                HStack(spacing: 10) {
                    Button {
                        self.song = nil
                        showEditSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .sheet(isPresented: $showEditSheet) {
                        EditSongOnServerView(isBeingShown: $showEditSheet, song: song)
                            .frame(minWidth: 800, minHeight: 500)
                    }

//                    Button {
//                        print((selectedItem ?? "") as String)
//                        alertType = .twoOptionsOneDelete
//                        showAlert = true
//                    } label: {
//                        Image(systemName: "minus")
//                    }
//                    .alert(isPresented: $showAlert) {
//                        switch alertType {
//                        case .singleOptionInformative:
//                            return Alert(title: Text("Som Removido Com Sucesso"), message: Text("O som \"\(selectedSongTitle)\" foi marcado como removido no servidor e a mudança será propagada para todos os clientes na próxima sincronização."), dismissButton: .cancel(Text("OK")))
//
//                        case .twoOptionsOneDelete:
//                            return Alert(title: Text("Remover \"\(selectedSongTitle)\""), message: Text("Tem certeza de que deseja remover o som \"\(selectedSongTitle)\"? A mudança será sincronizada com o servidor e propagada para todos os clientes na próxima sincronização."), primaryButton: .destructive(Text("Remover"), action: {
//                                guard let selectedItem else { return }
//                                removeSong(withId: selectedItem)
//                            }), secondaryButton: .cancel(Text("Cancelar")))
//
//                        default:
//                            return Alert(title: Text("Houve um Problema Ao Tentar Marcar a Música como Removida"), message: Text(alertErrorMessage), dismissButton: .cancel(Text("OK")))
//                        }
//                    }

                    Spacer()

                    Button("Enviar Músicas Já no App") {
                        showMoveDataSheet()
                    }
                    .sheet(isPresented: $showAddAlreadyOnAppSheet) {
                        MoveDataToServerView(isBeingShown: $showAddAlreadyOnAppSheet,
                                             data: fixedData!,
                                             chunkSize: 10,
                                             endpointEnding: "v3/import-songs/\(Secrets.assetOperationPassword)")
                            .frame(minWidth: 800, minHeight: 500)
                    }

                    Text("\(items.count.formattedString) itens")
                }
            }
            .navigationTitle("Músicas no Servidor")
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
                let url = URL(string: serverPath + "v3/all-songs")!
                
                var fetchedItems: [Song] = try await APIClient().getArray(from: url)
                
                fetchedItems.sort(by: { $0.dateAdded ?? Date() > $1.dateAdded ?? Date() })
                
                self.items = fetchedItems
            } catch {
                print(error)
            }
            
            await MainActor.run {
                showLoadingView = false
            }
        }
    }
    
    private func getSong(withID id: String, from items: [Song]) -> Song? {
        for item in items {
            if item.id == id {
                return item
            }
        }
        return nil
    }
    
    private func editSong(withId itemId: String) {
        guard let item = getSong(withID: itemId, from: items) else { return }
        self.song = item
        showEditSheet = true
    }

    private func replaceSongFile(withId itemId: String) {
//        guard let item = getSound(withID: itemId, from: sounds) else { return }
//        self.sound = item
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
//            showReplaceSheet = true
//        }
    }

    private func showMoveDataSheet() {
        Task {
            fixedData = Bundle.main.decodeJSON("song_data.json")
            fixedData?.sort(by: { $0.dateAdded ?? Date() > $1.dateAdded ?? Date() })
            showAddAlreadyOnAppSheet = true
        }
    }
}

struct ServerSongsCRUDView_Previews: PreviewProvider {
    
    static var previews: some View {
        ServerSongsCRUDView()
    }
}
