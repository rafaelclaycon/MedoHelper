//
//  EditSoundOnServerView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 30/04/23.
//

import SwiftUI

struct EditSoundOnServerView: View {
    
    @Binding var isBeingShown: Bool
    @State var sound: Sound
    @State var isEditing: Bool
    
    @State private var authors: [Author] = []
    @State private var selectedAuthor: Author.ID?
    @State private var showFilePicker = false
    @State private var selectedFile: URL? = nil
    
    // Alert
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // Progress View
    @State private var showSendProgress = false
    @State private var progressAmount = 0.0
    @State private var modalMessage = ""
    
    private var filename: String {
        return selectedFile?.lastPathComponent ?? ""
    }
    
    private var hasAllNecessaryData: Bool {
        if isEditing {
            return sound.title != "" && sound.description != "" && selectedAuthor != nil
        } else {
            return sound.title != "" && sound.description != "" && selectedAuthor != nil && selectedFile != nil
        }
    }
    
    private var idText: String {
        var text = "ID: \(sound.id)"
        if !isEditing {
            text += " (recém criado)"
        }
        return text
    }
    
    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Text(isEditing ? "Editando Som \"\(sound.title)\"" : "Criando Novo Som")
                    .font(.title)
                    .bold()
                
                Spacer()
            }
            
            HStack {
                Text(idText)
                    .foregroundColor(isEditing ? .primary : .gray)
                
                Spacer()
            }
            
            TextField("Título do Som", text: $sound.title)
            
            TextField("Descrição do Som", text: $sound.description)
            
            Picker("Autor: ", selection: $selectedAuthor) {
                Text("<Nenhum Autor selecionado>").tag(nil as Author.ID?)
                ForEach(authors) { author in
                    Text(author.name).tag(Optional(author.id))
                }
            }
            
            HStack(spacing: 30) {
                Button("Selecionar arquivo...") {
                    showFilePicker = true
                }
                .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.mp3]) { result in
                    do {
                        selectedFile = try result.get()
                        print(selectedFile as Any)
                    } catch {
                        print("Error selecting file: \(error.localizedDescription)")
                    }
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
                
                Text(filename)
            }
            
            HStack(spacing: 50) {
                //                DatePicker("Data de adição", selection: $sound.dateAdded, displayedComponents: .date)
                //                    .datePickerStyle(.compact)
                //                    .labelsHidden()
                //                    .frame(width: 110)
                
                Toggle("É ofensivo", isOn: $sound.isOffensive)
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
                        updateContent()
                    } else {
                        createContent()
                    }
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
            loadAuthors()
        }
        .disabled(showSendProgress)
        .sheet(isPresented: $showSendProgress) {
            SendingProgressView(isBeingShown: $showSendProgress, message: $modalMessage, currentAmount: $progressAmount, totalAmount: 2)
        }
    }
    
    func createContent() {
        Task {
            showSendProgress = true
            modalMessage = "Enviando Dados..."
            
            let url = URL(string: serverPath + "v3/create-sound")!
            guard let authorId = selectedAuthor else {
                alertTitle = "Dados Incompletos"
                alertMessage = "Selecione um Autor."
                return showingAlert = true
            }
            guard let fileURL = selectedFile else { return }
            guard let duration = await FileHelper.getDuration(of: fileURL) else { return }
            let content = MedoContent(sound: sound, authorId: authorId, duration: duration)
            print(content)
            do {
                let response = try await NetworkRabbit.post(data: content, to: url)
                
                print(response as Any)
                
                guard let createdContentId = response else {
                    alertTitle = "Falha ao Criar Som"
                    alertMessage = "O contentId não foi retornado pelo servidor."
                    return showingAlert = true
                }
                
                progressAmount = 1
                modalMessage = "Renomeando Arquivo..."
                
                let destinationURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let success = FileHelper.copyAndRenameFile(from: fileURL, to: destinationURL, with: "\(createdContentId).mp3")
                if success {
                    print("File copied and renamed successfully.")
                } else {
                    print("File copy and rename failed.")
                }
                
                // TODO: - Implement file upload
                
                progressAmount = 2
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
                    showSendProgress = false
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func updateContent() {
        Task {
            showSendProgress = true
            modalMessage = "Enviando Dados..."
            
            let url = URL(string: serverPath + "v3/update-content")!
            guard let authorId = selectedAuthor else {
                alertTitle = "Dados Incompletos"
                alertMessage = "Selecione um Autor."
                return showingAlert = true
            }
            // File and duration here
            let content = MedoContent(sound: sound, authorId: authorId, duration: sound.duration)
            print(content)
            do {
                let response = try await NetworkRabbit.put(in: url, data: content)
                
                print(response as Any)
                
                guard response else {
                    alertTitle = "Falha ao Atualizar o Som"
                    alertMessage = "Houve uma falha."
                    showSendProgress = false
                    return showingAlert = true
                }
                
                progressAmount = 1
                //modalMessage = "Renomeando Arquivo..."
                
//                let destinationURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//                let success = FileHelper.copyAndRenameFile(from: fileURL, to: destinationURL, with: "\(createdContentId).mp3")
//                if success {
//                    print("File copied and renamed successfully.")
//                } else {
//                    print("File copy and rename failed.")
//                }
                
                // TODO: - Implement file upload
                
                progressAmount = 2
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
                    showSendProgress = false
                    isBeingShown = false
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func loadAuthors() {
        Task {
            let url = URL(string: serverPath + "v3/all-authors")!
            do {
                authors = try await NetworkRabbit.get(from: url)
                authors.sort(by: { $0.name.preparedForComparison() < $1.name.preparedForComparison() })
                
                if !sound.authorId.isEmpty {
                    selectedAuthor = sound.authorId
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

struct CreateSoundOnServerView_Previews: PreviewProvider {
    
    static var previews: some View {
        EditSoundOnServerView(isBeingShown: .constant(true), sound: Sound(title: ""), isEditing: false)
    }
}
