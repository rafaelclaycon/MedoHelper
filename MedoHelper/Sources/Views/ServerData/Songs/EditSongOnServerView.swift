//
//  EditSongOnServerView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 03/09/23.
//

import SwiftUI

struct EditSongOnServerView: View {

    @Binding var isBeingShown: Bool
    @State var song: Song
    private let isEditing: Bool

    @State private var genres: [MusicGenre] = []
    @State private var selectedGenre: MusicGenre.ID?
    @State private var showFilePicker = false
    @State private var selectedFile: URL? = nil
    @State private var songUpdateEventId: String = ""

    // Alert
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertType: AlertType = .singleOptionInformative

    // Progress View
    @State private var showSendProgress = false
    @State private var progressAmount = 0.0
    @State private var totalAmount = 2.0
    @State private var modalMessage = ""

    @Environment(\.dismiss) private var dismiss
    
    private var filename: String {
        return selectedFile?.lastPathComponent ?? ""
    }
    
    private var hasAllNecessaryData: Bool {
        if isEditing {
            return song.title != "" && selectedGenre != nil
        } else {
            return song.title != "" && selectedGenre != nil && selectedFile != nil
        }
    }
    
    private var idText: String {
        var text = "ID: \(song.id)"
        if !isEditing {
            text += " (recém criado)"
        }
        return text
    }
    
    private var finderWarningAdjective: String {
        isEditing ? "edição" : "criação"
    }

    init(
        isBeingShown: Binding<Bool>,
        song: Song? = nil
    ) {
        _isBeingShown = isBeingShown
        self.isEditing = song != nil
        self._song = State(initialValue: song ?? Song(title: ""))
    }

    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Text(isEditing ? "Editando Música \"\(song.title)\"" : "Criando Nova Música")
                    .font(.title)
                    .bold()
                
                Spacer()
            }
            
            HStack {
                Text(idText)
                    .foregroundColor(isEditing ? .primary : .gray)
                
                Spacer()
            }
            
            TextField("Título da Música", text: $song.title)
            
            TextField("Descrição da Música", text: $song.description)
            
            Picker("Gênero: ", selection: $selectedGenre) {
                Text("<Nenhum Gênero Musical selecionado>").tag(nil as MusicGenre.ID?)
                ForEach(genres) { genre in
                    Text(genre.name).tag(Optional(genre.id))
                }
            }
            
            if !isEditing {
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
                    
                    Text(filename)
                }
            }
            
            if filename != "" {
                Text("Uma janela do Finder será aberta após a \(finderWarningAdjective) da música para que você tenha acesso ao arquivo renomeado para o servidor.")
                    .foregroundColor(.orange)
                    .fixedSize()
            }

            Toggle("É ofensivo", isOn: $song.isOffensive)

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
            loadGenres()
        }
        .disabled(showSendProgress)
        .sheet(isPresented: $showSendProgress) {
            SendingProgressView(isBeingShown: $showSendProgress, message: $modalMessage, currentAmount: $progressAmount, totalAmount: $totalAmount)
        }
        .alert(isPresented: $showingAlert) {
            switch alertType {
            case .twoOptionsOneContinue:
                return Alert(title: Text(alertTitle), message: Text(alertMessage), primaryButton: .default(Text("Continuar"), action: {
                    setVisibility(ofUpdate: songUpdateEventId, to: true)
                }), secondaryButton: .cancel(Text("Cancelar")))
            default:
                return Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func createContent() {
        Task {
            totalAmount = 2
            showSendProgress = true
            modalMessage = "Enviando Dados..."
            
            let url = URL(string: serverPath + "v3/create-song/\(assetOperationPassword)")!
            guard let genreId = selectedGenre else {
                alertType = .singleOptionInformative
                alertTitle = "Dados Incompletos"
                alertMessage = "Selecione um Autor."
                showSendProgress = false
                return showingAlert = true
            }
            guard let fileURL = selectedFile else { return }
            guard let duration = await FileHelper.getDuration(of: fileURL) else { return }
            let content = MedoContent(song: song, genreId: genreId, duration: duration)
            print(content)
            do {
                let response: CreateContentResponse? = try await NetworkRabbit.post(data: content, to: url)
                
                print(response as Any)
                
                guard let createdContentResponse = response else {
                    alertType = .singleOptionInformative
                    alertTitle = "Falha ao Criar Música"
                    alertMessage = "O servidor não retornou a resposta esperada."
                    return showingAlert = true
                }

                guard !createdContentResponse.eventId.isEmpty else {
                    alertType = .singleOptionInformative
                    alertTitle = "Falha ao Criar Música"
                    alertMessage = "O eventId retornado pelo servidor está vazio. Sem um eventId válido não é possível definir o UpdateEvent como visível mais para frente."
                    return showingAlert = true
                }

                guard !createdContentResponse.contentId.isEmpty else {
                    alertType = .singleOptionInformative
                    alertTitle = "Falha ao Criar Música"
                    alertMessage = "O contentId retornado pelo servidor está vazio. Sem um contentId válido não é possível renomear o arquivo de som."
                    return showingAlert = true
                }

                songUpdateEventId = createdContentResponse.eventId
                
                progressAmount = 1
                modalMessage = "Renomeando Arquivo..."
                
                let documentsFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                do {
                    try renameFile(from: fileURL, with: "\(createdContentResponse.contentId).mp3", saveTo: documentsFolder)
                } catch {
                    print(error)
                    alertType = .singleOptionInformative
                    alertTitle = "Falha Ao Renomear Arquivo"
                    alertMessage = error.localizedDescription
                    showSendProgress = false
                    return showingAlert = true
                }
                
                FileHelper.openFolderInFinder(documentsFolder)
                
                progressAmount = 2
                
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
                    showSendProgress = false
                }

                alertType = .twoOptionsOneContinue
                alertTitle = "Aguardando Subida do Arquivo para o Servidor"
                alertMessage = "Coloque o arquivo recém gerado em /Public/songs/ e clique em Continuar."
                showingAlert = true
            } catch {
                print(error)
                alertType = .singleOptionInformative
                alertTitle = "Falha ao Criar Música"
                alertMessage = error.localizedDescription
                showSendProgress = false
                return showingAlert = true
            }
        }
    }
    
    private func updateContent() {
        Task {
            totalAmount = 2
            showSendProgress = true
            modalMessage = "Enviando Dados..."

            let url = URL(string: serverPath + "v3/update-content/\(assetOperationPassword)")!
            guard let genreId = selectedGenre else {
                alertType = .singleOptionInformative
                alertTitle = "Dados Incompletos"
                alertMessage = "Selecione um Gênero Musical."
                return showingAlert = true
            }
            // File and duration here
            let content = MedoContent(song: song, genreId: genreId, duration: song.duration)
            print(content)
            do {
                let response = try await NetworkRabbit.put(in: url, data: content)

                print(response as Any)

                guard response else {
                    alertType = .singleOptionInformative
                    alertTitle = "Falha ao Atualizar a Música"
                    alertMessage = "Houve uma falha."
                    showSendProgress = false
                    return showingAlert = true
                }

                progressAmount = 1

                if let fileURL = selectedFile {
                    modalMessage = "Renomeando Arquivo..."
                    let documentsFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    do {
                        try renameFile(from: fileURL, with: "\(song.id).mp3", saveTo: documentsFolder)
                    } catch {
                        alertType = .singleOptionInformative
                        alertTitle = "Falha Ao Renomear Arquivo"
                        alertMessage = error.localizedDescription
                        showSendProgress = false
                        return showingAlert = true
                    }

                    FileHelper.openFolderInFinder(documentsFolder)
                }

                progressAmount = 2

                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
                    showSendProgress = false
                    isBeingShown = false
                }
            } catch {
                alertType = .singleOptionInformative
                alertTitle = "Falha ao Atualizar a Música"
                alertMessage = error.localizedDescription
                showSendProgress = false
                return showingAlert = true
            }
        }
    }
    
    private func loadGenres() {
        Task {
            let url = URL(string: serverPath + "v3/all-music-genres")!
            do {
                genres = try await NetworkRabbit.get(from: url)
                genres.sort(by: { $0.name.preparedForComparison() < $1.name.preparedForComparison() })
                
                if !song.genreId.isEmpty {
                    selectedGenre = song.genreId
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    private func renameFile(from fileURL: URL, with filename: String, saveTo destinationURL: URL) throws {
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: destinationURL.appending(path: filename).path(percentEncoded: false)) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        try FileHelper.copyAndRenameFile(from: fileURL, to: destinationURL, with: filename)
    }

    private func setVisibility(ofUpdate updateId: String, to newValue: Bool) {
        Task {
            totalAmount = 1
            showSendProgress = true
            modalMessage = "Definindo Visibilidade..."

            let url = URL(string: serverPath + "v3/change-update-visibility/\(updateId)/\(newValue == true ? "1" : "0")/\(assetOperationPassword)")!

            do {
                let response = try await NetworkRabbit.put(in: url, data: Optional<String>.none)

                print(response as Any)

                guard response else {
                    alertType = .singleOptionInformative
                    alertTitle = "Falha ao Tentar Tornar a Atualização Visível"
                    alertMessage = "Houve uma falha."
                    showSendProgress = false
                    return showingAlert = true
                }

                progressAmount = 1

                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
                    showSendProgress = false
                    dismiss()
                }
            } catch {
                alertType = .singleOptionInformative
                alertTitle = "Falha ao Tentar Tornar a Atualização Visível"
                alertMessage = error.localizedDescription
                showSendProgress = false
                return showingAlert = true
            }
        }
    }
}

struct EditSongOnServerView_Previews: PreviewProvider {
    static var previews: some View {
        EditSongOnServerView(isBeingShown: .constant(true), song: Song(title: ""))
    }
}
