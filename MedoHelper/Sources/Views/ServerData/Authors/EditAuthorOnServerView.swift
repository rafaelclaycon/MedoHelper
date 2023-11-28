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
    private let isEditing: Bool
    
    @State private var description: String = ""
    @State private var photoURL: String = ""

    // Alert
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    // Progress View
    @State private var showSendProgress = false
    @State private var progressAmount = 0.0
    @State private var modalMessage = ""
    
    private var idText: String {
        var text = "ID: \(author.id)"
        if !isEditing {
            text += " (recém criado)"
        }
        return text
    }

    init(
        isBeingShown: Binding<Bool>,
        author: Author? = nil
    ) {
        _isBeingShown = isBeingShown
        self.isEditing = author != nil
        self.author = author ?? Author(name: "")
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
            
            TextField("URL para Foto", text: $photoURL)

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
            SendingProgressView(isBeingShown: $showSendProgress, message: $modalMessage, currentAmount: $progressAmount, totalAmount: .constant(1))
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            description = author.description ?? ""
            photoURL = author.photo ?? ""
        }
    }
    
    func createAuthor() {
        Task {
            showSendProgress = true
            modalMessage = "Enviando Dados..."
            
            let url = URL(string: serverPath + "v3/create-author/\(assetOperationPassword)")!
            
            if description != "" {
                author.description = description
            }
            if photoURL != "" {
                author.photo = photoURL
            }
            dump(author)
            do {
                let response = try await NetworkRabbit.post(data: author, to: url)
                
                print(response as Any)
                
                progressAmount = 1
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
                    showSendProgress = false
                    isBeingShown = false
                }
            } catch {
                print(error)
            }
        }
    }
    
    func updateAuthor() {
        Task {
            progressAmount = 0
            showSendProgress = true
            modalMessage = "Enviando Dados..."

            let url = URL(string: serverPath + "v3/update-author/\(assetOperationPassword)")!

            let newAuthor: Author = .init(
                id: author.id,
                name: author.name,
                photo: photoURL,
                description: description
            )

            do {
                let response = try await NetworkRabbit.put(in: url, data: newAuthor)

                print(response as Any)

                guard response else {
                    alertTitle = "Falha ao Atualizar o Autor"
                    alertMessage = "Houve uma falha."
                    showSendProgress = false
                    return showingAlert = true
                }

                progressAmount = 1

                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
                    showSendProgress = false
                    isBeingShown = false
                }
            } catch {
                alertTitle = "Falha ao Atualizar o Autor"
                alertMessage = error.localizedDescription
                showSendProgress = false
                return showingAlert = true
            }
        }
    }
}

struct EditAuthorOnServerView_Previews: PreviewProvider {
    static var previews: some View {
        EditAuthorOnServerView(isBeingShown: .constant(true), author: Author(name: ""))
    }
}
