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
    @State private var externalLinks: [ExternalLink] = []

    @State private var showNewExternalLinkSheet = false
    @State private var selectedExternalLink: ExternalLink? = nil

    // Alert
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""

    // Progress View
    @State private var showSendProgress = false
    @State private var progressAmount = 0.0
    @State private var modalMessage = ""

    // MARK: - Computed Properties

    private var idText: String {
        var text = "ID: \(author.id)"
        if !isEditing {
            text += " (recém criado)"
        }
        return text
    }

    // MARK: - Initializers

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

            HStack {
                Text("Links Externos:")

                Spacer()
            }

            HStack(spacing: 10) {
                if externalLinks.isEmpty {
                    Text("Nenhum link externo cadastrado.")
                        .foregroundStyle(.gray)
                } else {
                    ForEach(externalLinks) {
                        ExternalLinkButton(
                            externalLink: $0,
                            onTapAction: { link in
                                self.selectedExternalLink = link
                                self.showNewExternalLinkSheet = true
                            }
                        )
                    }
                }

                Spacer()
            }

            HStack(spacing: 10) {
                Button {
                    self.selectedExternalLink = .init()
                    self.showNewExternalLinkSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .sheet(item: $selectedExternalLink) { link in
                    NewExternalLinkView(
                        externalLink: link,
                        saveAction: { newLink in
                            if let index = externalLinks.firstIndex(where: { $0.id == newLink.id }) {
                                externalLinks[index] = newLink
                            } else {
                                externalLinks.append(newLink)
                            }
                        },
                        removeAction: { link in
                            if let index = externalLinks.firstIndex(where: { $0.id == link.id }) {
                                externalLinks.remove(at: index)
                            }
                        }
                    )
                    .frame(minWidth: 500, minHeight: 300)
                }

                Spacer()
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
            SendingProgressView(
                message: modalMessage,
                currentAmount: progressAmount,
                totalAmount: 1
            )
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            description = author.description ?? ""
            photoURL = author.photo ?? ""
            externalLinks = decode(externalLinks: author.externalLinks)
        }
    }
    
    private func createAuthor() {
        Task {
            showSendProgress = true
            modalMessage = "Enviando Dados..."
            
            let url = URL(string: serverPath + "v3/create-author/\(Secrets.assetOperationPassword)")!
            
            if description != "" {
                author.description = description
            }
            if photoURL != "" {
                author.photo = photoURL
            }
            if !externalLinks.isEmpty {
                author.externalLinks = externalLinks.asJSONString()
            }
            dump(author)
            do {
                let response = try await APIClient().post(data: author, to: url)
                
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
    
    private func updateAuthor() {
        Task {
            progressAmount = 0
            showSendProgress = true
            modalMessage = "Enviando Dados..."

            let url = URL(string: serverPath + "v3/update-author/\(Secrets.assetOperationPassword)")!

            let newAuthor: Author = .init(
                id: author.id,
                name: author.name,
                photo: photoURL.isEmpty ? nil : photoURL,
                description: description,
                externalLinks: externalLinks.asJSONString()
            )

            do {
                let response = try await APIClient().put(in: url, data: newAuthor)

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

    private func decode(externalLinks incomingExternalLinks: String?) -> [ExternalLink] {
        guard let links = incomingExternalLinks else {
            return []
        }
        guard let jsonData = links.data(using: .utf8) else {
            return []
        }
        let decoder = JSONDecoder()
        do {
            let decodedLinks = try decoder.decode([SimplifiedExternalLink].self, from: jsonData)
            return decodedLinks.map { ExternalLink(symbol: $0.symbol, title: $0.title, color: $0.color, link: $0.link) }
        } catch {
            print("Error decoding JSON: \(error)")
            return []
        }
    }
}

struct EditAuthorOnServerView_Previews: PreviewProvider {
    static var previews: some View {
        EditAuthorOnServerView(isBeingShown: .constant(true), author: Author(name: ""))
    }
}
