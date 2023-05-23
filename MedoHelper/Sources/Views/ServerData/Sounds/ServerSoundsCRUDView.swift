//
//  ServerSoundsCRUDView.swift
//  MedoHelper
//
//  Created by Rafael Claycon Schmitt on 30/04/23.
//

import SwiftUI

struct ServerSoundsCRUDView: View {
    
    @State private var currentTab = 0
    @State private var sound = Sound(title: "")
    
    @State private var showAddAlreadyOnAppSheet = false
    
    @State private var sounds: [Sound] = []
    @State private var selectedSound: Sound.ID?
    @State private var showAddSheet = false
    @State private var showDeleteAlert = false
    
    private var selectedSoundTitle: String {
        guard let selectedSound = selectedSound else { return "" }
        guard let sound = getSound(withID: selectedSound, from: sounds) else { return "" }
        return sound.title
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Sons no Servidor")
                    .font(.title)
                    .bold()
                
                Spacer()
                
                Button("Enviar Sons Já no App") {
                    showAddAlreadyOnAppSheet = true
                }
                .sheet(isPresented: $showAddAlreadyOnAppSheet) {
                    MoveSoundsToServerView(isBeingShown: $showAddAlreadyOnAppSheet)
                        .frame(minWidth: 800, minHeight: 500)
                }
            }
            
            Table(sounds, selection: $selectedSound) {
                TableColumn("ID") { sound in
                    Text("\(sound.id)")
                        .onTapGesture(count: 2) {
                            self.sound = sound
                            showAddSheet = true
                        }
                }
                
                TableColumn("Título") { sound in
                    Text("\(sound.title)")
                        .onTapGesture(count: 2) {
                            self.sound = sound
                            showAddSheet = true
                        }
                }

                TableColumn("Data de Criação") { sound in
                    Text(sound.dateAdded?.toScreenString() ?? "")
                        .onTapGesture(count: 2) {
                            self.sound = sound
                            showAddSheet = true
                        }
                }
                
                TableColumn("Duração") { sound in
                    Text("\(sound.duration.asString())")
                        .onTapGesture(count: 2) {
                            self.sound = sound
                            showAddSheet = true
                        }
                }
                
//                TableColumn("Origem") { sound in
//                    Text(sound.isFromServer ?? false ? "Servidor" : "App")
//                        .onTapGesture(count: 2) {
//                            self.sound = sound
//                            showAddSheet = true
//                        }
//                }
            }
            
            HStack(spacing: 10) {
                Button {
                    self.sound = Sound(title: "")
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .sheet(isPresented: $showAddSheet) {
                    EditSoundOnServerView(isBeingShown: $showAddSheet, sound: sound, isEditing: sound.title != "")
                        .frame(minWidth: 800, minHeight: 500)
                }
                
                Button {
                    print((selectedSound ?? "") as String)
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "minus")
                }
                .alert(isPresented: $showDeleteAlert) {
                    Alert(title: Text("Remover \"\(selectedSoundTitle)\""), message: Text("Tem certeza de que deseja remover o som \"\(selectedSoundTitle)\"? A mudança será sincronizada com o servidor e propagada para todos os clientes na próxima sincronização."), primaryButton: .destructive(Text("Remover"), action: {
                        guard let selectedSound = selectedSound else { return }
                        removeSound(withId: selectedSound)
                    }), secondaryButton: .cancel(Text("Cancelar")))
                }
                
                Spacer()
                
                Text("\(sounds.count.formattedString) itens")
            }
        }
        .padding()
        .onAppear {
            fetchSounds()
        }
    }
    
    func fetchSounds() {
        Task {
            do {
                let url = URL(string: serverPath + "v3/all-sounds")!
                
                var fetchedSounds: [Sound] = try await NetworkRabbit.getArray(from: url)
//                for i in 0...(allSounds.count - 1) {
//                    allSounds[i].authorName = authorData.first(where: { $0.id == allSounds[i].authorId })?.name ?? Shared.unknownAuthor
//                }
                
                fetchedSounds.sort(by: { $0.dateAdded ?? Date() > $1.dateAdded ?? Date() })
                
                self.sounds = fetchedSounds
            } catch {
                print(error)
            }
        }
    }
    
    private func getSound(withID id: String, from sounds: [Sound]) -> Sound? {
        for sound in sounds {
            if sound.id == id {
                return sound
            }
        }
        return nil
    }
    
    private func removeSound(withId soundId: String) {
        Task {
            do {
                let url = URL(string: serverPath + "v3/remove-sound/\(soundId)")!
                let response = try await NetworkRabbit.put(in: url, data: nil as String?)
                
                print(response as Any)
            } catch {
                print(error)
            }
        }
    }
}

struct ServerSoundsCRUDView_Previews: PreviewProvider {
    
    static var previews: some View {
        ServerSoundsCRUDView()
    }
}
