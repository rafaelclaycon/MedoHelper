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
//                    if isEditing {
//                        updateContent()
//                    } else {
//                        createContent()
//                    }
                } label: {
                    Text(isEditing ? "Atualizar" : "Criar")
                        .padding(.horizontal)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!hasAllNecessaryData)
            }
        }
        .padding(.all, 26)
        .onAppear {
            //loadAuthors()
        }
        .disabled(showSendProgress)
//        .sheet(isPresented: $showSendProgress) {
//            SendingProgressView(isBeingShown: $showSendProgress, message: $modalMessage, currentAmount: $progressAmount, totalAmount: $totalAmount)
//        }
//        .alert(isPresented: $showingAlert) {
//            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
//        }
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
