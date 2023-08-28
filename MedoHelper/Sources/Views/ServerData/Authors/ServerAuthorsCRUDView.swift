//
//  ServerAuthorsCRUDView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 05/05/23.
//

import SwiftUI

struct ServerAuthorsCRUDView: View {

    @State private var author: Author? = nil
    
    @State private var showAddAlreadyOnAppSheet = false
    @State private var fixedData: [Author]? = nil
    
    @State private var authors: [Author] = []
    @State private var selectedItem: Author.ID?
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var searchText = ""

    // Alert
    @State private var showAlert = false
    @State private var alertType: AlertType = .singleOptionInformative
    @State private var alertErrorMessage: String = ""

    private var selectedAuthorName: String {
        guard let selectedItem = selectedItem else { return "" }
        guard let author = getAuthor(withID: selectedItem, from: authors) else { return "" }
        return author.name
    }
    
    private var searchResults: [Author] {
        if searchText.isEmpty {
            return authors
        } else {
            return authors.filter { author in
                let normalizedAuthorName = author.name.preparedForComparison()
                return normalizedAuthorName.contains(searchText.preparedForComparison())
            }
        }
    }
    
    var body: some View {
        VStack {
            Table(searchResults, selection: $selectedItem) {
                TableColumn("Nome", value: \.name)
            }.contextMenu(forSelectionType: Author.ID.self) { items in
                Section {
                    Button("Editar Autor") {
                        guard let selectedItemId = items.first else { return }
                        editAuthor(withId: selectedItemId)
                    }
                }
                
                Section {
                    Button("Ocultar Autor") {
                        showDeleteAlert = true
                    }
                }
            } primaryAction: { items in
                guard let selectedItemId = items.first else { return }
                editAuthor(withId: selectedItemId)
            }
            .searchable(text: $searchText)
            
            HStack(spacing: 10) {
                Button {
                    self.author = nil
                    showEditSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .sheet(isPresented: $showEditSheet) {
                    EditAuthorOnServerView(isBeingShown: $showEditSheet, author: author)
                        .frame(minWidth: 800, minHeight: 500)
                }
                .disabled(authors.count == 0)
                
                Button {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "minus")
                }
                .alert(isPresented: $showDeleteAlert) {
                    Alert(title: Text("Ocultar \"\(selectedAuthorName)\""), message: Text("Tem certeza de que deseja ocultar o(a) autor(a) \"\(selectedAuthorName)\"? A mudança será sincronizada com o servidor e propagada para todos os clientes na próxima sincronização."), primaryButton: .destructive(Text("Ocultar"), action: {
                        guard let selectedItem else { return }
                        hideAuthor(withId: selectedItem)
                    }), secondaryButton: .cancel(Text("Cancelar")))
                }
                .disabled(authors.count == 0)
                
                Spacer()
                
                Button("Enviar Autores Já no App") {
                    showMoveDataSheet()
                }
                .sheet(isPresented: $showAddAlreadyOnAppSheet) {
                    MoveDataToServerView(isBeingShown: $showAddAlreadyOnAppSheet,
                                         data: fixedData!,
                                         chunkSize: 100,
                                         endpointEnding: "v3/import-authors")
                        .frame(minWidth: 800, minHeight: 500)
                }
                .padding(.trailing, 10)
                .disabled(authors.count > 0)
                
                Text("\(authors.count.formattedString) itens")
            }
        }
        .navigationTitle("Autores no Servidor")
        .padding()
        .onAppear {
            fetchAuthors()
        }
        .onChange(of: showAddAlreadyOnAppSheet) { showAddAlreadyOnAppSheet in
            if showAddAlreadyOnAppSheet == false {
                fetchAuthors()
            }
        }
        .onChange(of: showEditSheet) { showEditSheet in
            if !showEditSheet {
                fetchAuthors()
            }
        }
    }
    
    private func fetchAuthors() {
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
    
    private func hideAuthor(withId authorId: String) {
        Task {
            do {
                let url = URL(string: serverPath + "v3/author/\(authorId)")!
                let response = try await NetworkRabbit.delete(in: url, data: nil as String?)
                
                print(response as Any)
                
                sleep(1)
                
                fetchAuthors()
            } catch {
                print(error)
            }
        }
    }
    
    private func showMoveDataSheet() {
        Task {
            fixedData = Bundle.main.decodeJSON("author_data.json")
            fixedData?.sort(by: { $0.name.preparedForComparison() < $1.name.preparedForComparison() })
            showAddAlreadyOnAppSheet = true
        }
    }
}

struct ServerAuthorsCRUDView_Previews: PreviewProvider {
    static var previews: some View {
        ServerAuthorsCRUDView()
    }
}
