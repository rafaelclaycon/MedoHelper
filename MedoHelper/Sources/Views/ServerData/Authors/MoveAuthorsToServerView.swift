//
//  MoveAuthorsToServerView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 02/05/23.
//

import SwiftUI

struct MoveAuthorsToServerView: View {
    
    @Binding var isBeingShown: Bool
    
    @State private var authors: [Author] = []
    @State private var isSending: Bool = false
    @State private var sendingResponse: String = ""
    @State private var chunks: Array<Array<Author>> = Array<Array<Author>>()
    @State private var currentChunk: CGFloat = 0
    
    private var authorCount: String {
        "\(authors.count.formattedString) autores"
    }
    
    private var progressViewText: String {
        "Enviando autores (\(Int(currentChunk))/\(chunks.count))..."
    }
    
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
            
            HStack {
                Text(authorCount)
                
                Spacer()
                
                Button("Cancelar") {
                    isBeingShown = false
                }
                
                Button("Enviar") {
                    sendAuthors()
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
            authors = Bundle.main.decodeJSON("author_data.json")
            authors.sort(by: { $0.name.preparedForComparison() < $1.name.preparedForComparison() })
        }
    }
    
    func sendAuthors() {
        Task {
            let url = URL(string: serverPath + "v3/import-authors")!
            
            // The whole array is split into parts because Vapor cannot handle all 400+ items at once.
            let chunkSize = 100
            chunks = stride(from: 0, to: authors.count, by: chunkSize).map {
                Array(authors[$0..<min($0 + chunkSize, authors.count)])
            }
            
            for chunk in chunks {
                do {
                    _ = try await NetworkRabbit.post(data: chunk, to: url)
                    if Int(currentChunk) < chunks.count {
                        currentChunk += 1
                    }
                    sleep(1)
                } catch {
                    print(error)
                }
            }
            
            chunks = Array<Array<Author>>()
        }
    }
}

struct MoveAuthorsToServerView_Previews: PreviewProvider {
    
    static var previews: some View {
        MoveAuthorsToServerView(isBeingShown: .constant(true))
    }
}
