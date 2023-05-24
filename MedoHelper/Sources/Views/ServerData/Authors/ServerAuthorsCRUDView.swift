//
//  ServerAuthorsCRUDView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 05/05/23.
//

import SwiftUI

struct ServerAuthorsCRUDView: View {
    
    @State private var currentTab = 0
    @State private var author = Author(name: "")
    
    @State private var showAddAlreadyOnAppSheet = false
    
    @State private var authors: [Author] = []
    @State private var selectedItem: Author.ID?
    @State private var showAddSheet = false
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
                TableColumn("ID") { author in
                    Text("\(author.id)")
                        .onTapGesture(count: 2) {
                            self.author = author
                            showAddSheet = true
                        }
                }
                
                TableColumn("Nome") { author in
                    Text("\(author.name)")
                        .onTapGesture(count: 2) {
                            self.author = author
                            showAddSheet = true
                        }
                }

                TableColumn("Foto") { author in
                    Text(author.photo ?? "")
                        .onTapGesture(count: 2) {
                            self.author = author
                            showAddSheet = true
                        }
                }
                
                TableColumn("Descrição") { author in
                    Text(author.description ?? "")
                        .onTapGesture(count: 2) {
                            self.author = author
                            showAddSheet = true
                        }
                }
            }
            
            HStack(spacing: 10) {
                Button {
                    self.author = Author(name: "")
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .sheet(isPresented: $showAddSheet) {
                    EditAuthorOnServerView(isBeingShown: $showAddSheet, author: author, isEditing: author.name != "")
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
