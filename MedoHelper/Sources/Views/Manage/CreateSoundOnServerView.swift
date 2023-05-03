//
//  CreateSoundOnServerView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 30/04/23.
//

import SwiftUI

struct CreateSoundOnServerView: View {
    
    @Binding var sound: ProtoSound
    @State private var authors: [Author] = []
    @State private var selectedAuthor: Author.ID?
    
    var body: some View {
        VStack {
            TextField("Título do Som", text: $sound.title)
                .padding()
            
            TextField("Descrição do Som", text: $sound.description)
                .padding()
            
            
            Picker("Autor: ", selection: $selectedAuthor) {
                Text("<Nenhum Autor selecionado>").tag(nil as Author.ID?)
                ForEach(authors) { author in
                    Text(author.name).tag(Optional(author.id))
                }
            }
            .padding()
            
            HStack {
                Text("")
                
                Button("Selecionar arquivo...") {
                    print("Escolher pressionado")
                }
            }
            .padding()
            
            HStack(spacing: 50) {
//                DatePicker("Data de adição", selection: $sound.dateAdded, displayedComponents: .date)
//                    .datePickerStyle(.compact)
//                    .labelsHidden()
//                    .frame(width: 110)
                
                Toggle("É ofensivo", isOn: $sound.isOffensive)
            }
            .padding()
            
            HStack {
                Spacer()
                
                Button {
                    sendContent()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "paperplane")
                        Text("Enviar")
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.horizontal)

            Text(sound.successMessage)
                .padding()
        }
        .onAppear {
            loadAuthors()
        }
    }
    
    func sendContent() {
        Task {
            let url = URL(string: "http://127.0.0.1:8080/api/v3/create-sound")!
            guard let authorId = selectedAuthor else { return }
            let content = MedoContent(sound: sound, authorId: authorId)
            do {
                try await NetworkRabbit.post(data: content, to: url)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func loadAuthors() {
        Task {
            let url = URL(string: "http://127.0.0.1:8080/api/v3/all-authors")!
            do {
                authors = try await NetworkRabbit.get(from: url)
                authors.sort(by: { $0.name.preparedForComparison() < $1.name.preparedForComparison() })
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

struct CreateSoundOnServerView_Previews: PreviewProvider {
    
    static var previews: some View {
        CreateSoundOnServerView(sound: .constant(ProtoSound(title: "", description: "", filename: "", dateAdded: Date(), isOffensive: false, successMessage: "...")))
    }
}
