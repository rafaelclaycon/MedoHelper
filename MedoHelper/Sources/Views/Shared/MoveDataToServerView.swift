//
//  MoveDataToServerView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 20/06/23.
//

import SwiftUI

struct MoveDataToServerView<T: Codable & CustomDebugStringConvertible & Identifiable>: View {
    
    @Binding var isBeingShown: Bool
    
    let data: [T]
    let chunkSize: Int
    let endpointEnding: String
    
    @State private var isSending: Bool = false
    @State private var sendingResponse: String = ""
    @State private var chunks: Array<Array<T>> = Array<Array<T>>()
    @State private var currentChunk: CGFloat = 0
    
    // Alert
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    private var itemCount: String {
        "\(data.count.formattedString) itens"
    }
    
    private var progressViewText: String {
        "Enviando músicas (\(Int(currentChunk))/\(chunks.count))..."
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                if data.isEmpty {
                    Text("Sem dados.")
                        .foregroundColor(.gray)
                        .padding(200)
                } else {
                    Table(data) {
                        TableColumn("Título") { item in
                            Text(item.debugDescription)
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
                    sendData()
                }
            }
            .disabled(chunks.count > 0)
            
            if chunks.count > 0 {
                ProgressView(progressViewText, value: currentChunk, total: CGFloat(chunks.count))
                    .padding()
            }
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .cancel(Text("OK")))
        }
    }
    
    private func sendData() {
        Task {
            let url = URL(string: serverPath + endpointEnding)!
            
            // The whole array is split into parts because Vapor cannot handle all data at once.
            chunks = stride(from: 0, to: data.count, by: chunkSize).map {
                Array(data[$0..<min($0 + chunkSize, data.count)])
            }
            
            var errors: [String] = []
            
            for chunk in chunks {
                do {
                    _ = try await NetworkRabbit.post(data: chunk, to: url)
                    sleep(1)
                } catch {
                    errors.append("De \"\(chunk.first?.debugDescription ?? "")\" a \"\(chunk.last?.debugDescription ?? "")\": \(error.localizedDescription)")
                }
                
                if Int(currentChunk) < chunks.count {
                    currentChunk += 1
                }
            }
            
            chunks = []
            
            if errors.count > 0 {
                showAlert(title: errors.count == 1 ? "Ocorreu 1 Erro Durante o Envio" : "Ocorreram \(errors.count) Erros Durante o Envio",
                          message: errors.joined(separator: "\n").lengthLimit(280))
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

struct MoveDataToServerView_Previews: PreviewProvider {
    static var previews: some View {
        MoveDataToServerView<Sound>(isBeingShown: .constant(true), data: [Sound](), chunkSize: 10, endpointEnding: "v3/import-sounds")
    }
}
