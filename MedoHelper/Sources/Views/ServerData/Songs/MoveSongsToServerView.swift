//
//  MoveSongsToServerView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 24/05/23.
//

import SwiftUI

struct MoveSongsToServerView: View {
    
    @Binding var isBeingShown: Bool
    
    @State private var items: [Song] = []
    @State private var isSending: Bool = false
    @State private var sendingResponse: String = ""
    @State private var chunks: Array<Array<Song>> = Array<Array<Song>>()
    @State private var currentChunk: CGFloat = 0
    
    // Alert
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    private var itemCount: String {
        "\(items.count.formattedString) itens"
    }
    
    private var progressViewText: String {
        "Enviando músicas (\(Int(currentChunk))/\(chunks.count))..."
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                if items.isEmpty {
                    HStack(spacing: 10) {
                        ProgressView()
                        
                        Text("Carregando...")
                            .foregroundColor(.gray)
                    }
                } else {
                    Table(items) {
                        TableColumn("ID", value: \.id)
                        TableColumn("Título", value: \.title)
                        TableColumn("Data de Criação") { sound in
                            Text(sound.dateAdded?.displayString ?? "")
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
                Text(itemCount)
                
                Spacer()
                
                Button("Cancelar") {
                    isBeingShown = false
                }
                
                Button("Enviar") {
                    sendSongs()
                }
            }
            .disabled(chunks.count > 0)
            
            if chunks.count > 0 {
                ProgressView(progressViewText, value: currentChunk, total: CGFloat(chunks.count))
                    .padding()
            }
        }
        .padding()
        .onAppear {
            items = Bundle.main.decodeJSON("song_data.json")
            items.sort(by: { $0.dateAdded ?? Date() > $1.dateAdded ?? Date() })
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .cancel(Text("OK")))
        }
    }
    
    private func sendSongs() {
        Task {
            let url = URL(string: serverPath + "v3/import-songs")!
            
            // The whole array is split into parts because Vapor cannot handle all items at once.
            let chunkSize = 10
            chunks = stride(from: 0, to: items.count, by: chunkSize).map {
                Array(items[$0..<min($0 + chunkSize, items.count)])
            }
            
            var errors: [String] = []
            
            for chunk in chunks {
                do {
                    _ = try await APIClient().post(data: chunk, to: url)
                    sleep(1)
                } catch {
                    errors.append("De \"\(chunk.first?.title ?? "")\" a \"\(chunk.last?.title ?? "")\": \(error.localizedDescription)")
                }
                
                if Int(currentChunk) < chunks.count {
                    currentChunk += 1
                }
            }
            
            chunks = Array<Array<Song>>()
            
            if errors.count > 0 {
                showAlert("Ocorreram Erros Durante o Envio", errors.joined(separator: "\n"))
            }
        }
    }
    
    private func showAlert(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

struct MoveSongsToServerView_Previews: PreviewProvider {
    
    static var previews: some View {
        MoveSongsToServerView(isBeingShown: .constant(true))
    }
}
