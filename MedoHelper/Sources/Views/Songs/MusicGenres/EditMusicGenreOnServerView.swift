//
//  EditMusicGenreOnServerView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 03/09/23.
//

import SwiftUI

struct EditMusicGenreOnServerView: View {

    @Binding var isBeingShown: Bool
    @State var genre: MusicGenre
    private let isEditing: Bool

    // Progress View
    @State private var showSendProgress = false
    @State private var progressAmount = 0.0
    @State private var modalMessage = ""

    private var idText: String {
        var text = "ID: \(genre.id)"
        if !isEditing {
            text += " (recém criado)"
        }
        return text
    }

    private var hasAllNecessaryData: Bool {
        genre.symbol != "" && genre.name != ""
    }

    init(
        isBeingShown: Binding<Bool>,
        genre: MusicGenre? = nil
    ) {
        _isBeingShown = isBeingShown
        self.isEditing = genre != nil
        self._genre = State(initialValue: genre ?? MusicGenre(symbol: "", name: ""))
    }

    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Text(isEditing ? "Editando Gênero \"\(genre.name)\"" : "Criando Novo Gênero Musical")
                    .font(.title)
                    .bold()
                
                Spacer()
            }
            
            HStack {
                Text(idText)
                    .foregroundColor(isEditing ? .primary : .gray)
                
                Spacer()
            }
            
            TextField("Símbolo", text: $genre.symbol)
            
            TextField("Nome", text: $genre.name)

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
                    createMusicGenre()
                } label: {
                    Text(isEditing ? "Atualizar" : "Criar")
                        .padding(.horizontal)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!hasAllNecessaryData)
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
    }

    func createMusicGenre() {
        Task {
            showSendProgress = true
            modalMessage = "Enviando Dados..."

            let url = URL(string: serverPath + "v3/create-music-genre/\(Secrets.assetOperationPassword)")!

            dump(genre)

            do {
                let response = try await APIClient().post(data: genre, to: url)

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
}

struct EditMusicGenreOnServerView_Previews: PreviewProvider {
    static var previews: some View {
        EditMusicGenreOnServerView(
            isBeingShown: .constant(true),
            genre: MusicGenre(id: "123", symbol: "", name: "", isHidden: false)
        )
    }
}
