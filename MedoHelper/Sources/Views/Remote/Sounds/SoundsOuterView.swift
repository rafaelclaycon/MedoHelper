//
//  SoundsOuterView.swift
//  MedoHelper
//
//  Created by Rafael Claycon Schmitt on 30/04/23.
//

import SwiftUI

struct SoundsOuterView: View {
    
    @State private var currentTab = 0
    @State private var sound = ProtoSound(title: "", description: "", filename: "", dateAdded: Date(), isOffensive: false, successMessage: "...")
    
    @State private var showAddAlreadyOnAppSheet = false
    
    @State private var sounds: [Sound] = [Sound(title: "Ai, eu também")]
    @State private var selectedSounds: Sound.ID?
    @State private var showAddSheet = false
    
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
            
            Table(sounds, selection: $selectedSounds) {
                TableColumn("ID", value: \.id)
                TableColumn("Título", value: \.title)
//                TableColumn("Foto") { author in
//                    Text(author.photo ?? "")
//                }
                TableColumn("Data de Criação") { sound in
                    Text(sound.dateAdded?.toISO8601String() ?? "")
                        .onTapGesture(count: 2) {
                            print(sound.title)
                        }
                }
                TableColumn("Duração") { sound in
                    Text("\(sound.duration)")
                }
                TableColumn("Origem") { sound in
                    Text(sound.isFromServer ?? false ? "Servidor" : "App")
                }
            }
            
            HStack(spacing: 10) {
                Button {
                    showAddSheet.toggle()
                } label: {
                    Image(systemName: "plus")
                }
                .sheet(isPresented: $showAddSheet) {
                    CreateSoundOnServerView(sound: $sound, isBeingShown: $showAddSheet)
                }
                
                Button {
                    print("Remove")
                } label: {
                    Image(systemName: "minus")
                }
                
                Spacer()
            }
        }
        .padding()
    }
    
    
}

struct SoundsOuterView_Previews: PreviewProvider {
    
    static var previews: some View {
        SoundsOuterView()
    }
}
