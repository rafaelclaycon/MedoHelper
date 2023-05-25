//
//  ServerAuthorsCRUDView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 05/05/23.
//

import SwiftUI

struct ServerAuthorsCRUDView: View {
    
    @State private var author = Author(name: "")
    
    @State private var showAddAlreadyOnAppSheet = false
    
    @State private var authors: [Author] = []
    @State private var selectedItem: Author.ID?
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    
    private var selectedAuthorName: String {
        guard let selectedItem = selectedItem else { return "" }
        guard let author = getAuthor(withID: selectedItem, from: authors) else { return "" }
        return author.name
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("Autores no Servidor")
                    .font(.title)
                    .bold()
                
                Spacer()
                
                Button("Enviar Autores Já no App") {
                    showAddAlreadyOnAppSheet = true
                }
                .sheet(isPresented: $showAddAlreadyOnAppSheet) {
                    MoveAuthorsToServerView(isBeingShown: $showAddAlreadyOnAppSheet)
                        .frame(minWidth: 800, minHeight: 500)
                }
            }
            
            Table(authors, selection: $selectedItem) {
                TableColumn("Nome", value: \.name)
            }.contextMenu(forSelectionType: Author.ID.self) { items in
                Section {
                    Button("Editar Som") {
                        guard let selectedItemId = items.first else { return }
                        editAuthor(withId: selectedItemId)
                    }
                }
                
                Section {
                    Button("Remover Som") {
//                        guard let selectedItemId = items.first else { return }
//                        selectedSound = selectedItemId
//                        alertType = .twoOptionsOneDelete
//                        showAlert = true
                    }
                }
            } primaryAction: { items in
                guard let selectedItemId = items.first else { return }
                editAuthor(withId: selectedItemId)
            }
            
            HStack(spacing: 10) {
                Button {
                    self.author = Author(name: "")
                    showEditSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .sheet(isPresented: $showEditSheet) {
                    EditAuthorOnServerView(isBeingShown: $showEditSheet, author: author, isEditing: author.name != "")
                        .frame(minWidth: 800, minHeight: 500)
                }
                
                Button {
                    print((selectedItem ?? "") as String)
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "minus")
                }
                .alert(isPresented: $showDeleteAlert) {
                    Alert(title: Text("Remover \"\(selectedAuthorName)\""), message: Text("Tem certeza de que deseja remover o(a) autor(a) \"\(selectedAuthorName)\"? A mudança será sincronizada com o servidor e propagada para todos os clientes na próxima sincronização."), primaryButton: .destructive(Text("Remover"), action: {
                        guard let selectedItem = selectedItem else { return }
                        removeAuthor(withId: selectedItem)
                    }), secondaryButton: .cancel(Text("Cancelar")))
                }
                
                Spacer()
                
                Text("\(authors.count.formattedString) itens")
            }
        }
        .padding()
        .onAppear {
            fetchAuthors()
        }
    }
    
    func fetchAuthors() {
        Task {
            let url = URL(string: serverPath + "v3/all-authors")!
            
            do {
                var fetchedAuthors: [Author] = try await NetworkRabbit.getArray(from: url)
                fetchedAuthors.sort(by: { $0.name.preparedForComparison() < $1.name.preparedForComparison() })
                self.authors = fetchedAuthors
            } catch {
                print(error)
            }
        }
    }
    
    private func getAuthor(withID id: String, from authors: [Author]) -> Author? {
        for author in authors {
            if author.id == id {
                return author
            }
        }
        return nil
    }
    
    private func editAuthor(withId itemId: String) {
        guard let item = getAuthor(withID: itemId, from: authors) else { return }
        self.author = item
        showEditSheet = true
    }
    
    private func removeAuthor(withId authorId: String) {
        Task {
            do {
                let url = URL(string: serverPath + "v3/author/\(authorId)")!
                let response = try await NetworkRabbit.delete(in: url, data: nil as String?)
                
                print(response as Any)
            } catch {
                print(error)
            }
        }
    }
}

struct ServerAuthorsCRUDView_Previews: PreviewProvider {
    
    static var previews: some View {
        ServerAuthorsCRUDView()
    }
}
