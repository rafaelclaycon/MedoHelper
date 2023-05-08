//
//  MoveSoundsToServerView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 05/05/23.
//

import SwiftUI

struct MoveSoundsToServerView: View {
    
    @Binding var isBeingShown: Bool
    
    @State private var sounds: [Sound] = []
    @State private var isSending: Bool = false
    @State private var sendingResponse: String = ""
    
    private let successMessage = "Sons enviados com sucesso!"
    
    private var soundCount: String {
        "\(sounds.count) sons"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                if sounds.isEmpty {
                    HStack(spacing: 10) {
                        ProgressView()
                        
                        Text("Carregando sons...")
                            .foregroundColor(.gray)
                    }
                } else {
                    Table(sounds) {
                        TableColumn("ID", value: \.id)
                        TableColumn("Título", value: \.title)
                        TableColumn("Data de Criação") { sound in
                            Text(sound.dateAdded?.toScreenString() ?? "")
                                .onTapGesture(count: 2) {
                                    print(sound.title)
                                }
                        }
                        TableColumn("Duração") { sound in
                            Text("\(sound.duration.asString())")
                        }
                    }
                }
                
                if isSending {
                    ProgressView()
                        .scaleEffect(2, anchor: .center)
                        .frame(width: 200, height: 140)
                        .background(.regularMaterial)
                        .cornerRadius(25)
                }
            }
            
            HStack {
                Text(soundCount)
                
                Spacer()
                
                Button("Cancelar") {
                    isBeingShown = false
                }
                
                Button("Enviar") {
                    sendSounds()
                }
            }
            
            Text(sendingResponse)
                .foregroundColor(sendingResponse == successMessage ? .green : .primary)
                .padding()
        }
        .padding()
        .onAppear {
            sounds = Bundle.main.decodeJSON("sound_data.json")
            sounds.sort(by: { $0.dateAdded ?? Date() > $1.dateAdded ?? Date() })
        }
    }
    
    func sendSounds() {
        Task {
            let url = URL(string: serverPath + "v3/import-sounds")!
            
            // The whole array is split into parts because Vapor cannot handle all 400+ items at once.
            let chunkSize = 10
            let chunks = stride(from: 0, to: sounds.count, by: chunkSize).map {
                Array(sounds[$0..<min($0 + chunkSize, sounds.count)])
            }
            print(chunks.count)
            print(chunks)
            
            for chunk in chunks {
                do {
                    _ = try await NetworkRabbit.post(data: chunk, to: url)
                    sendingResponse = sendingResponse + "\n" + successMessage
                    sleep(2)
                } catch {
                    sendingResponse = sendingResponse + "\n" + error.localizedDescription
                }
            }
        }
    }
}

struct MoveSoundsToServerView_Previews: PreviewProvider {
    
    static var previews: some View {
        MoveSoundsToServerView(isBeingShown: .constant(true))
    }
}
