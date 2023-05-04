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
        return sound.title != "" && sound.description != "" && selectedAuthor != nil && selectedFile != nil
    }
    
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
                .disabled(!hasAllNecessaryData)
            }
            .padding(.horizontal)
            
            Text(sound.successMessage)
                .padding()
        }
        .onAppear {
            loadAuthors()
        }
        .disabled(showSendProgress)
        .sheet(isPresented: $showSendProgress) {
            SendingProgressView(isBeingShown: $showSendProgress, message: $modalMessage, currentAmount: $progressAmount, totalAmount: 2)
        }
    }
    
    func sendContent() {
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
    
    func loadAuthors() {
        Task {
            let url = URL(string: serverPath + "v3/all-authors")!
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
