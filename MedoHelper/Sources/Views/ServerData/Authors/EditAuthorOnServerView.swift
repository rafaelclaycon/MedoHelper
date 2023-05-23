//
//  EditAuthorOnServerView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 19/05/23.
//

import SwiftUI

struct EditAuthorOnServerView: View {
    
    @Binding var isBeingShown: Bool
    @State var author: Author
    @State var isEditing: Bool
    
    @State private var description: String = ""
    @State private var showFilePicker = false
    @State private var selectedPhoto: URL? = nil
    
    // Progress View
    @State private var showSendProgress = false
    @State private var progressAmount = 0.0
    @State private var modalMessage = ""
    
    private var filename: String {
        return selectedPhoto?.lastPathComponent ?? ""
    }
    
    private var idText: String {
        var text = "ID: \(author.id)"
        if !isEditing {
            text += " (recém criado)"
        }
        return text
    }
    
    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Text(isEditing ? "Editando Autor \"\(author.name)\"" : "Criando Novo Autor")
                    .font(.title)
                    .bold()
                
                Spacer()
            }
            
            HStack {
                Text(idText)
                    .foregroundColor(isEditing ? .primary : .gray)
                
                Spacer()
            }
            
            TextField("Nome do Autor", text: $author.name)
            
            TextField("Descrição do Autor", text: $description)
            
            HStack(spacing: 30) {
                Button("Selecionar arquivo...") {
                    showFilePicker = true
                }
                .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.mp3]) { result in
                    do {
                        selectedPhoto = try result.get()
                        print(selectedPhoto as Any)
                    } catch {
                        print("Error selecting file: \(error.localizedDescription)")
                    }
                }
//                .alert(isPresented: $showingAlert) {
//                    Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
//                }
                
                Text(filename)
            }
            
            Spacer()
            
            HStack(spacing: 15) {
                Spacer()
                
                Button {
                    isBeingShown = false
                } label: {
                    Text("Cancelar")
                        .padding(.horizontal)
                }
                .keyboardShortcut(.cancelAction)
                
                Button {
                    if isEditing {
                        updateAuthor()
                    } else {
                        createAuthor()
                    }
                } label: {
                    Text(isEditing ? "Atualizar" : "Criar")
                        .padding(.horizontal)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(author.name == "")
            }
        }
        .padding(.all, 26)
        .disabled(showSendProgress)
        .sheet(isPresented: $showSendProgress) {
            SendingProgressView(isBeingShown: $showSendProgress, message: $modalMessage, currentAmount: $progressAmount, totalAmount: 2)
        }
    }
    
    func createAuthor() {
        Task {
            showSendProgress = true
            modalMessage = "Enviando Dados..."
            
            let url = URL(string: serverPath + "v3/create-author/total-real-password-3")!
            
            if description != "" {
                author.description = description
            }
            dump(author)
            do {
                let response = try await NetworkRabbit.post(data: author, to: url)
                
                print(response as Any)
                
                progressAmount = 1
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
                    showSendProgress = false
                }
            } catch {
                print(error)
            }
        }
    }
    
    func updateAuthor() {
        print("NOT IMPLEMENTED YET")
    }
}

struct EditAuthorOnServerView_Previews: PreviewProvider {
    
    static var previews: some View {
        EditAuthorOnServerView(isBeingShown: .constant(true), author: Author(name: ""), isEditing: false)
    }
}
