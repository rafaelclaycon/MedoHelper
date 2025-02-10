//
//  MoveSoundsToServerView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 05/05/23.
//

import SwiftUI

//struct MoveSoundsToServerView: View {
//    
//    @Binding var isBeingShown: Bool
//    
//    @State private var sounds: [Sound] = []
//    @State private var isSending: Bool = false
//    @State private var sendingResponse: String = ""
//    @State private var chunks: Array<Array<Sound>> = Array<Array<Sound>>()
//    @State private var currentChunk: CGFloat = 0
//    
//    private var soundCount: String {
//        "\(sounds.count.formattedString) sons"
//    }
//    
//    private var progressViewText: String {
//        "Enviando sons (\(Int(currentChunk))/\(chunks.count))..."
//    }
//    
//    var body: some View {
//        VStack(spacing: 20) {
//            ZStack {
//                if sounds.isEmpty {
//                    HStack(spacing: 10) {
//                        ProgressView()
//                        
//                        Text("Carregando sons...")
//                            .foregroundColor(.gray)
//                    }
//                } else {
//                    Table(sounds) {
//                        TableColumn("ID", value: \.id)
//                        TableColumn("Título", value: \.title)
//                        TableColumn("Data de Criação") { sound in
//                            Text(sound.dateAdded?.toScreenString() ?? "")
//                                .onTapGesture(count: 2) {
//                                    print(sound.title)
//                                }
//                        }
//                        TableColumn("Duração") { sound in
//                            Text("\(sound.duration.asString())")
//                        }
//                    }
//                }
//                
//                if isSending {
//                    ProgressView()
//                        .scaleEffect(2, anchor: .center)
//                        .frame(width: 200, height: 140)
//                        .background(.regularMaterial)
//                        .cornerRadius(25)
//                }
//            }
//            
//            HStack {
//                Text(soundCount)
//                
//                Spacer()
//                
//                Button("Cancelar") {
//                    isBeingShown = false
//                }
//                
//                Button("Enviar") {
//                    sendSounds()
//                }
//            }
//            .disabled(chunks.count > 0)
//            
//            if chunks.count > 0 {
//                ProgressView(progressViewText, value: currentChunk, total: CGFloat(chunks.count))
//                    .padding()
//            }
//        }
//        .padding()
//        .onAppear {
//            sounds = Bundle.main.decodeJSON("sound_data.json")
//            sounds.sort(by: { $0.dateAdded ?? Date() > $1.dateAdded ?? Date() })
//        }
//    }
//    
//    private func sendSounds() {
//        Task {
//            let url = URL(string: serverPath + "v3/import-sounds")!
//            
//            // The whole array is split into parts because Vapor cannot handle all 1.000+ items at once.
//            let chunkSize = 10
//            chunks = stride(from: 0, to: sounds.count, by: chunkSize).map {
//                Array(sounds[$0..<min($0 + chunkSize, sounds.count)])
//            }
//            
//            for chunk in chunks {
//                do {
//                    _ = try await APIClient().post(data: chunk, to: url)
//                    if Int(currentChunk) < chunks.count {
//                        currentChunk += 1
//                    }
//                    sleep(1)
//                } catch {
//                    print(error)
//                }
//            }
//            
//            chunks = Array<Array<Sound>>()
//        }
//    }
//}
//
//struct MoveSoundsToServerView_Previews: PreviewProvider {
//    
//    static var previews: some View {
//        MoveSoundsToServerView(isBeingShown: .constant(true))
//    }
//}
