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
    @State private var showAddSheet = false
    @State private var showDeleteAlert = false
    
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
                        MoveSoundsToServerView(isBeingShown: $showAddAlreadyOnAppSheet)
                            .frame(minWidth: 800, minHeight: 500)
                    }
                }
                
                Table(items, selection: $selectedItem) {
                    TableColumn("ID") { song in
                        Text("\(song.id)")
                            .onTapGesture(count: 2) {
                                self.song = song
                                showAddSheet = true
                            }
                    }
                    
                    TableColumn("Título") { song in
                        Text("\(song.title)")
                            .onTapGesture(count: 2) {
                                self.song = song
                                showAddSheet = true
                            }
                    }
                    
                    TableColumn("Gênero") { song in
                        Text(song.genre.name)
                            .onTapGesture(count: 2) {
                                self.song = song
                                showAddSheet = true
                            }
                    }
                    
                    TableColumn("Duração") { song in
                        Text("\(song.duration.asString())")
                            .onTapGesture(count: 2) {
                                self.song = song
                                showAddSheet = true
                            }
                    }
                    
                    TableColumn("Data de Adição") { song in
                        Text(song.dateAdded?.toScreenString() ?? "")
                            .onTapGesture(count: 2) {
                                self.song = song
                                showAddSheet = true
                            }
                    }
                }
                
                HStack(spacing: 10) {
                    Button {
                        self.song = Song(title: "")
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
//                    .sheet(isPresented: $showAddSheet) {
//                        EditSoundOnServerView(isBeingShown: $showAddSheet, sound: sound, isEditing: sound.title != "")
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
}

struct ServerSongsCRUDView_Previews: PreviewProvider {
    
    static var previews: some View {
        ServerSongsCRUDView()
    }
}
