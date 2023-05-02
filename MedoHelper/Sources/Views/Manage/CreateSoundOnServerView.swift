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
    @State private var selectedAuthor: Author?
    
    var body: some View {
        VStack {
            TextField("Título do Som", text: $sound.title)
                .padding()
            
            TextField("Descrição do Som", text: $sound.description)
                .padding()
            
            if authors.isEmpty {
                Text("Carregando...")
            } else {
                Picker("Autor", selection: $selectedAuthor) {
                    ForEach(authors) { author in
                        Text(author.name).tag(author)
                    }
                }
                .padding()
                .onChange(of: selectedAuthor) { author in
                    if let author = author {
                        print("Selected author: \(author.name)")
                    }
                }
            }
            
            Text("Autor: \(selectedAuthor?.name ?? "")")
            
            Button("Update selected author") {
                selectedAuthor = authors.randomElement()
            }
            
            HStack {
                Text("")
                
                Button("Selecionar arquivo...") {
                    print("Escolher pressionado")
                }
            }
            .padding()
            
            HStack(spacing: 50) {
                DatePicker("Data de adição", selection: $sound.dateAdded, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(width: 110)
                
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
            let content = MedoContent(title: "O aí ó", authorId: "abcd", description: "o ai o", contentFileId: "fdfdfdfdf.mp3", creationDate: "2023-04-27T00:00:00Z", duration: 2.24, isOffensive: true)
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
                selectedAuthor = authors[0]
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
