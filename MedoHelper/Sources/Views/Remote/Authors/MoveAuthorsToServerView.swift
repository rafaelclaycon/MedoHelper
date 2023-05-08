//
//  MoveAuthorsToServerView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 02/05/23.
//

import SwiftUI

struct MoveAuthorsToServerView: View {
    
    @State private var authors: [Author] = []
    @State private var isSending: Bool = false
    @State private var sendingResponse: String = ""
    
    private let successMessage = "Autores enviados com sucesso!"
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Table(authors) {
                    TableColumn("ID", value: \.id)
                    TableColumn("Nome", value: \.name)
                    TableColumn("Foto") { author in
                        Text(author.photo ?? "")
                    }
                    TableColumn("Descrição") { author in
                        Text(author.description ?? "")
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
            
            Button("Enviar") {
                sendAuthors()
            }
            
            Text(sendingResponse)
                .foregroundColor(sendingResponse == successMessage ? .green : .primary)
                .padding()
        }
        .padding()
        .onAppear {
            authors = Bundle.main.decodeJSON("author_data.json")
        }
    }
    
    func sendAuthors() {
        Task {
            let url = URL(string: serverPath + "v3/import-authors")!
            
            // The whole array is split into parts because Vapor cannot handle all 400+ items at once.
            let chunkSize = 100
            let chunks = stride(from: 0, to: authors.count, by: chunkSize).map {
                Array(authors[$0..<min($0 + chunkSize, authors.count)])
            }
            print(chunks.count)
            print(chunks)
            
            for chunk in chunks {
                do {
                    _ = try await NetworkRabbit.post(data: chunk, to: url)
                    sendingResponse = successMessage
                    sleep(1)
                } catch {
                    sendingResponse = sendingResponse + " " + error.localizedDescription
                }
            }
        }
    }
}

struct MoveAuthorsToServerView_Previews: PreviewProvider {
    
    static var previews: some View {
        MoveAuthorsToServerView()
    }
}
