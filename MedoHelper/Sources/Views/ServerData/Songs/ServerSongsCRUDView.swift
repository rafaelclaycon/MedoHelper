//
//  ServerSongsCRUDView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 23/05/23.
//

import SwiftUI

struct ServerSongsCRUDView: View {
    
    @State private var song = Song(title: "")
    @State private var items: [Song] = []
    @State private var selectedItem: Sound.ID?
    
    @State private var showLoadingView = false
    @State private var showAddAlreadyOnAppSheet = false
    @State private var showEditSheet = false
    @State private var showAlert = false
    @State private var alertType: AlertType = .singleOptionInformative
    @State private var alertErrorMessage: String = ""
    
    private var selectedSongTitle: String {
//        guard let selectedSound = selectedSound else { return "" }
//        guard let sound = getSound(withID: selectedSound, from: sounds) else { return "" }
//        return sound.title
        return ""
    }
    
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Text("Músicas no Servidor")
                        .font(.title)
                        .bold()
                    
                    Spacer()
                    
                    Button("Enviar Músicas Já no App") {
                        showAddAlreadyOnAppSheet = true
                    }
                    .sheet(isPresented: $showAddAlreadyOnAppSheet) {
                        MoveSongsToServerView(isBeingShown: $showAddAlreadyOnAppSheet)
                            .frame(minWidth: 800, minHeight: 500)
                    }
                }
                
                Table(items, selection: $selectedItem) {
                    TableColumn("Título", value: \.title)
                    
                    TableColumn("Gênero", value: \.genre.name)
                        .width(min: 50, max: 100)
                    
                    TableColumn("Adicionado em") { song in
                        Text(song.dateAdded?.toScreenString() ?? "")
                    }
                    .width(min: 50, max: 100)
                    
                    TableColumn("Duração") { song in
                        Text("\(song.duration.asString())")
                    }
                    .width(min: 50, max: 100)
                }.contextMenu(forSelectionType: Song.ID.self) { items in
                    Section {
                        Button("Editar Som") {
                            guard let selectedItemId = items.first else { return }
                            editSong(withId: selectedItemId)
                        }
                    }
                    
                    Section {
                        Button("Remover Som") {
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
                
                HStack(spacing: 10) {
                    Button {
                        self.song = Song(title: "")
                        showEditSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
//                    .sheet(isPresented: $showEditSheet) {
//                        EditSongOnServerView(isBeingShown: $showEditSheet, sound: sound, isEditing: sound.title != "")
//                            .frame(minWidth: 800, minHeight: 500)
//                    }
                    
                    Spacer()
                    
                    Text("\(items.count.formattedString) itens")
                }
            }
            .padding()
            .onAppear {
                fetchItems()
            }
            .onChange(of: showAddAlreadyOnAppSheet) { showAddAlreadyOnAppSheet in
                if showAddAlreadyOnAppSheet == false {
                    fetchItems()
                }
            }
            
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
                
                var fetchedItems: [Song] = try await NetworkRabbit.getArray(from: url)
                
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
}

struct ServerSongsCRUDView_Previews: PreviewProvider {
    
    static var previews: some View {
        ServerSongsCRUDView()
    }
}
