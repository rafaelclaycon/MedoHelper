//
//  AddOrEditContentView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 26/07/26.
//

import SwiftUI

/// Add/edit sheet shared by sounds and songs. A type toggle (create mode only) switches
/// which type-specific field (author vs. genre) is shown; everything else is common.
struct AddOrEditContentView: View {

    private let isEditing: Bool
    private let originalFileId: String
    private let originalDuration: Double
    private let sourceSound: Sound?
    private let sourceSong: Song?

    @State private var id: String
    @State private var contentType: ContentType
    @State private var title: String
    @State private var description: String
    @State private var isOffensive: Bool

    @State private var authors: [Author] = []
    @State private var selectedAuthor: Author.ID?

    @State private var genres: [MusicGenre] = []
    @State private var selectedGenre: MusicGenre.ID?

    @State private var showFilePicker = false
    @State private var selectedFile: URL? = nil
    @State private var contentUpdateEventId: String = ""

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

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    private let contentRepository: ContentRepositoryProtocol

    // MARK: - Computed Properties

    private var filename: String {
        return selectedFile?.lastPathComponent ?? ""
    }

    private var hasAllNecessaryData: Bool {
        let hasCommonData = title != "" && description != ""
        let hasTypeSpecificData = contentType == .sound ? selectedAuthor != nil : selectedGenre != nil
        if isEditing {
            return hasCommonData && hasTypeSpecificData
        } else {
            return hasCommonData && hasTypeSpecificData && selectedFile != nil
        }
    }

    private var idText: String {
        var text = "ID: \(id)"
        if !isEditing {
            text += " (recém criado)"
        }
        return text
    }

    private var finderWarningAdjective: String {
        let adjective = isEditing ? "edição" : "criação"
        let contentNoun = contentType == .sound ? "do som" : "da música"
        return "\(adjective) \(contentNoun)"
    }

    private var titleText: String {
        if isEditing {
            return contentType == .sound ? "Editando Som \"\(title)\"" : "Editando Música \"\(title)\""
        } else {
            return contentType == .sound ? "Criando Novo Som" : "Criando Nova Música"
        }
    }

    private var creationFailureTitle: String {
        contentType == .sound ? "Falha ao Criar Som" : "Falha ao Criar Música"
    }

    private var updateFailureTitle: String {
        contentType == .sound ? "Falha ao Atualizar o Som" : "Falha ao Atualizar a Música"
    }

    private var uploadFolderName: String {
        contentType == .sound ? "sounds" : "songs"
    }

    // MARK: - Initializer

    init(
        item: ContentListItem? = nil,
        contentRepository: ContentRepositoryProtocol
    ) {
        self.isEditing = item != nil
        self.contentRepository = contentRepository

        self._id = State(initialValue: item?.id ?? UUID().uuidString)
        self._contentType = State(initialValue: item?.contentType ?? .sound)
        self._title = State(initialValue: item?.title ?? "")
        self._description = State(initialValue: item?.description ?? "")
        self._isOffensive = State(initialValue: item?.isOffensive ?? false)

        self.originalFileId = item?.sound?.filename ?? item?.song?.filename ?? ""
        self.originalDuration = item?.duration ?? 0
        self.sourceSound = item?.sound
        self.sourceSong = item?.song
    }

    // MARK: - View Body

    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Text(titleText)
                    .font(.title)
                    .bold()

                Spacer()
            }

            HStack {
                Text(idText)
                    .foregroundColor(isEditing ? .primary : .gray)

                Spacer()
            }

            if !isEditing {
                Picker("Tipo: ", selection: $contentType) {
                    Text("Som").tag(ContentType.sound)
                    Text("Música").tag(ContentType.song)
                }
                .pickerStyle(.segmented)
            }

            TextField(contentType == .sound ? "Título do Som" : "Título da Música", text: $title)

            TextField(contentType == .sound ? "Descrição do Som" : "Descrição da Música", text: $description)

            if contentType == .sound {
                Picker("Autor: ", selection: $selectedAuthor) {
                    Text("<Nenhum Autor selecionado>").tag(nil as Author.ID?)
                    ForEach(authors) { author in
                        Text(author.name).tag(Optional(author.id))
                    }
                }
            } else {
                Picker("Gênero: ", selection: $selectedGenre) {
                    Text("<Nenhum Gênero Musical selecionado>").tag(nil as MusicGenre.ID?)
                    ForEach(genres) { genre in
                        Text(genre.name).tag(Optional(genre.id))
                    }
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
                Text("Uma janela do Finder será aberta após a \(finderWarningAdjective) para que você tenha acesso ao arquivo renomeado para o servidor.")
                    .foregroundColor(.orange)
                    .fixedSize()
            }

            Toggle("É ofensivo", isOn: $isOffensive)

            Spacer()

            HStack(spacing: 15) {
                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Cancelar")
                        .padding(.horizontal)
                }
                .keyboardShortcut(.cancelAction)

                Button {
                    Task {
                        if isEditing {
                            await updateContent()
                        } else {
                            await createContent()
                        }
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
            loadGenres()
        }
        .disabled(showSendProgress)
        .sheet(isPresented: $showSendProgress) {
            SendingProgressView(
                message: modalMessage,
                currentAmount: progressAmount,
                totalAmount: totalAmount
            )
        }
        .alert(isPresented: $showingAlert) {
            switch alertType {
            case .twoOptionsOneContinue:
                return Alert(title: Text(alertTitle), message: Text(alertMessage), primaryButton: .default(Text("Continuar"), action: {
                    setVisibility(ofUpdate: contentUpdateEventId, to: true)
                }), secondaryButton: .cancel(Text("Cancelar")))
            default:
                return Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    // MARK: - Functions

    private func createContent() async {
        totalAmount = 2
        showSendProgress = true
        modalMessage = "Enviando Dados..."

        if contentType == .sound {
            guard selectedAuthor != nil else {
                alertType = .singleOptionInformative
                alertTitle = "Dados Incompletos"
                alertMessage = "Selecione um Autor."
                showSendProgress = false
                return showingAlert = true
            }
        } else {
            guard selectedGenre != nil else {
                alertType = .singleOptionInformative
                alertTitle = "Dados Incompletos"
                alertMessage = "Selecione um Gênero Musical."
                showSendProgress = false
                return showingAlert = true
            }
        }
        guard let fileURL = selectedFile else { return }
        guard let duration = await FileHelper.getDuration(of: fileURL) else { return }

        let content = MedoContent(
            id: UUID(uuidString: id) ?? UUID(),
            title: title,
            authorId: contentType == .sound ? (selectedAuthor ?? "") : "",
            description: description,
            fileId: "",
            creationDate: Date.now.iso8601String,
            duration: duration,
            isOffensive: isOffensive,
            musicGenre: contentType == .song ? selectedGenre : nil,
            contentType: contentType,
            isHidden: false
        )
        print(content)
        do {
            guard let response = try await contentRepository.create(content: content) else {
                alertType = .singleOptionInformative
                alertTitle = creationFailureTitle
                alertMessage = "O servidor não retornou a resposta esperada."
                return showingAlert = true
            }

            guard !response.eventId.isEmpty else {
                alertType = .singleOptionInformative
                alertTitle = creationFailureTitle
                alertMessage = "O eventId retornado pelo servidor está vazio. Sem um eventId válido não é possível definir o UpdateEvent como visível mais para frente."
                return showingAlert = true
            }

            guard !response.contentId.isEmpty else {
                alertType = .singleOptionInformative
                alertTitle = creationFailureTitle
                alertMessage = "O contentId retornado pelo servidor está vazio. Sem um contentId válido não é possível renomear o arquivo."
                return showingAlert = true
            }

            contentUpdateEventId = response.eventId

            progressAmount = 1
            modalMessage = "Renomeando Arquivo..."

            let documentsFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            do {
                try FileHelper.renameFile(from: fileURL, with: "\(response.contentId).mp3", saveTo: documentsFolder)
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
            alertMessage = "Coloque o arquivo recém gerado em /Public/\(uploadFolderName)/ e clique em Continuar."
            showingAlert = true
        } catch {
            print(error)
            alertType = .singleOptionInformative
            alertTitle = creationFailureTitle
            alertMessage = error.localizedDescription
            showSendProgress = false
            return showingAlert = true
        }
    }

    private func updateContent() async {
        totalAmount = 2
        showSendProgress = true
        modalMessage = "Enviando Dados..."

        if contentType == .sound {
            guard selectedAuthor != nil else {
                alertType = .singleOptionInformative
                alertTitle = "Dados Incompletos"
                alertMessage = "Selecione um Autor."
                showSendProgress = false
                return showingAlert = true
            }
        } else {
            guard selectedGenre != nil else {
                alertType = .singleOptionInformative
                alertTitle = "Dados Incompletos"
                alertMessage = "Selecione um Gênero Musical."
                showSendProgress = false
                return showingAlert = true
            }
        }

        let content = MedoContent(
            id: UUID(uuidString: id) ?? UUID(),
            title: title,
            authorId: contentType == .sound ? (selectedAuthor ?? "") : "",
            description: description,
            fileId: originalFileId,
            creationDate: Date.now.iso8601String,
            duration: originalDuration,
            isOffensive: isOffensive,
            musicGenre: contentType == .song ? selectedGenre : nil,
            contentType: contentType,
            isHidden: false
        )
        print(content)
        do {
            try await contentRepository.update(content: content)

            progressAmount = 2

            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
                showSendProgress = false
                dismiss()
            }
        } catch {
            alertType = .singleOptionInformative
            alertTitle = updateFailureTitle
            alertMessage = error.localizedDescription
            showSendProgress = false
            return showingAlert = true
        }
    }

    private func loadAuthors() {
        Task {
            let url = URL(string: serverPath + "v3/all-authors")!
            do {
                authors = try await APIClient().get(from: url)
                authors.sort(by: { $0.name.preparedForComparison() < $1.name.preparedForComparison() })

                if let sound = sourceSound, !sound.authorId.isEmpty {
                    selectedAuthor = sound.authorId
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    private func loadGenres() {
        Task {
            let url = URL(string: serverPath + "v3/all-music-genres")!
            do {
                genres = try await APIClient().get(from: url)
                genres.sort(by: { $0.name.preparedForComparison() < $1.name.preparedForComparison() })

                if let song = sourceSong, !song.genreId.isEmpty {
                    selectedGenre = song.genreId
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    private func setVisibility(ofUpdate updateId: String, to newValue: Bool) {
        Task {
            totalAmount = 1
            showSendProgress = true
            modalMessage = "Definindo Visibilidade..."

            let url = URL(string: serverPath + "v3/change-update-visibility/\(updateId)/\(newValue == true ? "1" : "0")/\(Secrets.assetOperationPassword)")!

            do {
                let response = try await APIClient().put(in: url, data: Optional<String>.none)

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

// MARK: - Preview

#Preview {
    AddOrEditContentView(contentRepository: ContentRepository())
}
