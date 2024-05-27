//
//  ReactionsCRUDView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 01/05/24.
//

import SwiftUI

struct ReactionsCRUDView: View {

    @State private var reactions: [ReactionDTO] = []

    @State private var isInEditMode: Bool = false
    @State private var showFileSelector: Bool = false

    @State private var searchText = ""
    @State private var selectedItem: ReactionDTO.ID?
    @State private var reaction: ReactionDTO? = nil
    @State private var showLoadingView: Bool = false

    @State private var showEditSheet = false

    // Progress View
    @State private var showSendProgress = false
    @State private var progressAmount = 0.0
    @State private var totalAmount = 2.0
    @State private var modalMessage = ""

    // Alert
    @State private var showAlert = false
    @State private var alertType: AlertType = .singleOptionInformative
    @State private var alertErrorMessage: String = ""

    // MARK: - Computed Properties

    private var searchResults: [ReactionDTO] {
        if searchText.isEmpty {
            return reactions
        } else {
            return reactions.filter { reaction in
                return reaction.title.contains(searchText.preparedForComparison())
            }
        }
    }

    // MARK: - Environment

    @Environment(\.colorScheme) var colorScheme

    // MARK: - View Body

    var body: some View {
        VStack {
            if isInEditMode {
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Modo de Edição Ativado")
                            .bold()
                            .foregroundStyle(.red)

                        Text("Edite e ordene as reações como deseja que elas apareçam no app.")
                            .foregroundStyle(.red)
                    }

                    Spacer()
                }
                .padding()
                .background {
                    Rectangle()
                        .foregroundColor(.red)
                        .opacity(colorScheme == .dark ? 0.3 : 0.15)
                }
            }

            VStack {
                Table(searchResults, selection: $selectedItem) {
                    TableColumn("Posição") { reaction in
                        Text("\(reaction.position)")
                    }
                    .width(min: 50, max: 50)

                    TableColumn("Título", value: \.title)

                    TableColumn("Sons") { reaction in
                        guard let sounds = reaction.sounds else { return Text("0") }
                        return Text("\(sounds.count)")
                    }
                    .width(min: 50, max: 50)
                }
                .disabled(!isInEditMode)
                //            .contextMenu(forSelectionType: Sound.ID.self) { items in
                //                Section {
                //                    Button("Editar Metadados do Som") {
                //                        guard let selectedItemId = items.first else { return }
                //                        editSound(withId: selectedItemId)
                //                    }
                //
                //                    Button("Substituir Arquivo do Som") {
                //                        guard let selectedItemId = items.first else { return }
                //                        replaceSoundFile(withId: selectedItemId)
                //                    }
                //                }
                //
                //                Section {
                //                    Button("Remover Som") {
                //                        guard let selectedItemId = items.first else { return }
                //                        selectedItem = selectedItemId
                //                        alertType = .twoOptionsOneDelete
                //                        showAlert = true
                //                    }
                //                }
                //            } primaryAction: { items in
                //                guard let selectedItemId = items.first else { return }
                //                editSound(withId: selectedItemId)
                //            }
                .searchable(text: $searchText)

                HStack(spacing: 20) {
//                    HStack(spacing: 10) {
//                        Button {
//                            self.reaction = nil
//                            showEditSheet = true
//                        } label: {
//                            Image(systemName: "plus")
//                        }
//                        .sheet(isPresented: $showEditSheet) {
//                            EditReactionView(isBeingShown: $showEditSheet, reaction: reaction)
//                                .frame(minWidth: 800, minHeight: 500)
//                        }
//
//                        Button {
//                            // print((selectedItem ?? "") as String)
//                            alertType = .twoOptionsOneDelete
//                            showAlert = true
//                        } label: {
//                            Image(systemName: "minus")
//                        }
//                    }
//                    .disabled(!isInEditMode)
                    //                .alert(isPresented: $showAlert) {
                    //                    switch alertType {
                    //                    case .singleOptionInformative:
                    //                        return Alert(
                    //                            title: Text("Som Removido Com Sucesso"),
                    //                            message: Text("O som \"\(selectedSoundTitle)\" foi marcado como removido no servidor e a mudança será propagada para todos os clientes na próxima sincronização."),
                    //                            dismissButton: .cancel(Text("OK")) {
                    //                                fetchSounds()
                    //                            }
                    //                        )
                    //
                    //                    case .twoOptionsOneDelete:
                    //                        return Alert(title: Text("Remover \"\(selectedSoundTitle)\""), message: Text("Tem certeza de que deseja remover o som \"\(selectedSoundTitle)\"? A mudança será sincronizada com o servidor e propagada para todos os clientes na próxima sincronização."), primaryButton: .destructive(Text("Remover"), action: {
                    //                            guard let selectedItem else { return }
                    //                            removeSound(withId: selectedItem)
                    //                        }), secondaryButton: .cancel(Text("Cancelar")))
                    //
                    //                    default:
                    //                        return Alert(title: Text("Houve um Problema Ao Tentar Marcar o Som como Removido"), message: Text(alertErrorMessage), dismissButton: .cancel(Text("OK")))
                    //                    }
                    //                }

                    Button("Importar de Arquivo JSON") {
                        reactions = Bundle.main.decodeJSON("reactions_data.json")
                        reactions.sort(by: { $0.position < $1.position })
                    }
//                    .fileImporter(
//                        isPresented: $showFileSelector,
//                        allowedContentTypes: [.json],
//                        allowsMultipleSelection: false
//                    ) { result in
//                        switch result {
//                        case .success(let urls):
//                            guard let url = urls.first else { return }
//                            decodeJSON(from: url)
//                        case .failure(let error):
//                            print("Error selecting file: \(error.localizedDescription)")
//                        }
//                    }
                    .disabled(!isInEditMode)

//                    Button("Importar das Pastas") {
//                        print("")
//                    }
//                    .disabled(!isInEditMode)

                    Spacer()

                    //                Button("Copiar títulos") {
                    //                    copyTitlesToClipboard()
                    //                }

                    //                Button("Enviar Sons Já no App") {
                    //                    showMoveDataSheet()
                    //                }
                    //                .sheet(isPresented: $showAddAlreadyOnAppSheet) {
                    //                    MoveDataToServerView(isBeingShown: $showAddAlreadyOnAppSheet,
                    //                                         data: fixedData!,
                    //                                         chunkSize: 10,
                    //                                         endpointEnding: "v3/import-sounds/\(assetOperationPassword)")
                    //                        .frame(minWidth: 800, minHeight: 500)
                    //                }

                    Text("\(reactions.count.formattedString) itens")

                    Button {
                        if isInEditMode {
                            sendAll()
                        } else {
                            isInEditMode.toggle()
                        }
                    } label: {
                        Text(isInEditMode ? "Enviar Dados" : "Iniciar Edição")
                            .padding(.horizontal)
                    }
                    .keyboardShortcut(.defaultAction)
                }
                .frame(height: 40)
            }
            .navigationTitle("Reações")
            .padding()
            .sheet(isPresented: $showSendProgress) {
                SendingProgressView(
                    isBeingShown: $showSendProgress,
                    message: $modalMessage,
                    currentAmount: $progressAmount,
                    totalAmount: $totalAmount
                )
            }
            .onAppear {
                loadReactions()
            }
        }
        .overlay {
            if showLoadingView {
                LoadingView()
            }
        }
    }

    // MARK: - Functions

    private func loadReactions() {
        Task {
            await MainActor.run {
                showLoadingView = true
            }

            do {
                let url = URL(string: serverPath + "v4/reactions")!

                let serverReactions: [AppReaction] = try await NetworkRabbit.getArray(from: url)
                var dtos = serverReactions.map { ReactionDTO(appReaction: $0) }
                dtos.sort(by: { $0.position < $1.position })

                self.reactions = dtos
            } catch {
                print(error)
            }

            await MainActor.run {
                showLoadingView = false
            }
        }
    }

    private func sendAll() {
        Task {
            totalAmount = Double(reactions.count)
            showSendProgress = true
            modalMessage = "Enviando Dados..."
            progressAmount = 0

            do {
                let reactionsUrl = URL(string: serverPath + "v4/delete-all-reactions/\(reactionsPassword)")!
                let soundsUrl = URL(string: serverPath + "v4/delete-all-reaction-sounds/\(reactionsPassword)")!
                print(reactionsUrl.absoluteString)
                print(soundsUrl.absoluteString)
                guard try await NetworkRabbit.delete(in: reactionsUrl) else {
                    print("Não foi possível apagar as Reações.")
                    return
                }
                guard try await NetworkRabbit.delete(in: soundsUrl) else {
                    print("Não foi possível apagar os sons das Reações.")
                    return
                }

                print("Reactions count: \(reactions.count)")
                for reaction in reactions {
                    try await send(reaction: AppReaction(dto: reaction))

                    if let sounds = reaction.sounds {
                        let dtos = sounds.map { ReactionSoundDTO(reactionSound: $0, reactionId: reaction.id) }
                        try await send(reactionSounds: dtos)
                    }

                    progressAmount += 1
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
                    showSendProgress = false
                }
            } catch {
                print(error)
//                alertType = .singleOptionInformative
//                alertTitle = "Falha ao Criar o Som"
//                alertMessage = error.localizedDescription
                showSendProgress = false
                // return showingAlert = true
            }
        }
    }

    private func send(reaction: AppReaction) async throws {
        let url = URL(string: serverPath + "v4/create-reaction/\(reactionsPassword)")!
        let _ = try await NetworkRabbit.post(data: reaction, to: url)
    }

    private func send(reactionSounds: [ReactionSoundDTO]) async throws {
        let url = URL(string: serverPath + "v4/add-sounds-to-reaction/\(reactionsPassword)")!
        let _ = try await NetworkRabbit.post(data: reactionSounds, to: url)
    }
}

#Preview {
    ReactionsCRUDView()
}
