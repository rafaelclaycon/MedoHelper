//
//  ReactionsCRUDView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 01/05/24.
//

import SwiftUI

struct ReactionsCRUDView: View {

    @State private var reactions: [ReactionDTO] = []

    @State private var searchText = ""
    @State private var selectedItem: ReactionDTO.ID?
    @State private var reaction: ReactionDTO? = nil
    @State private var showLoadingView: Bool = false

    @State private var showEditSheet = false

    @StateObject private var editReactionEnv = EditReactionHelper()

    @State private var didChangeReactionOrder: Bool = false

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

                    TableColumn("Data de última atualização") { reaction in
                        return Text(reaction.lastUpdate.formattedDate)
                    }
                }
                .contextMenu(forSelectionType: Sound.ID.self) { items in
                    Section {
                        Button("Editar Reação") {
                            guard let selectedItemId = items.first else { return }
                            editReaction(withId: selectedItemId)
                        }
                    }
                } primaryAction: { items in
                    guard let selectedItemId = items.first else { return }
                    editReaction(withId: selectedItemId)
                }
                .searchable(text: $searchText)

                HStack(spacing: 20) {
                    HStack(spacing: 10) {
                        Button {
                            self.editReactionEnv.reaction = nil
                            showEditSheet = true
                        } label: {
                            Image(systemName: "plus")
                        }

                        Button {
                            // print((selectedItem ?? "") as String)
//                            alertType = .twoOptionsOneDelete
//                            showAlert = true
                        } label: {
                            Image(systemName: "minus")
                        }
                    }

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
                        importAndSendPreExistingReactions()
                    }

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

                    Button {
                        didChangeReactionOrder = true
                        moveDown(selectedID: selectedItem)
                    } label: {
                        Label("Mover", systemImage: "chevron.down")
                    }
                    .disabled(selectedItem == nil)

                    Button {
                        didChangeReactionOrder = true
                        moveUp(selectedID: selectedItem)
                    } label: {
                        Label("Mover", systemImage: "chevron.up")
                    }
                    .disabled(selectedItem == nil)

                    Text("\(reactions.count.formattedString) itens")

                    Button {
                        print("TO IMPLEMENT")
                    } label: {
                        Text("Enviar Dados")
                            .padding(.horizontal)
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(didChangeReactionOrder)
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
            .sheet(isPresented: $showEditSheet) {
                EditReactionView(
                    isBeingShown: $showEditSheet,
                    onChangeAction: { loadReactions() }
                )
                .frame(minWidth: 1024, minHeight: 700)
                .environmentObject(editReactionEnv)
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

                guard !dtos.isEmpty else {
                    await MainActor.run {
                        showLoadingView = false
                    }
                    return
                }

                for i in 0...(dtos.count - 1) {
                    let reactionUrl = URL(string: serverPath + "v4/reaction/\(dtos[i].id)")!
                    dtos[i].sounds = try await NetworkRabbit.getArray(from: reactionUrl)
                }

                self.reactions = dtos
            } catch {
                print(error)
            }

            await MainActor.run {
                showLoadingView = false
            }
        }
    }

    private func reaction(withId id: String) -> ReactionDTO? {
        for reaction in reactions {
            if reaction.id == id {
                return reaction
            }
        }
        return nil
    }

    private func editReaction(withId itemId: String) {
        guard let item = reaction(withId: itemId) else { return }
        self.editReactionEnv.reaction = item
        showEditSheet = true
    }

    private func importAndSendPreExistingReactions() {
        guard reactions.isEmpty else {
            return print("TEM CERTEZA QUE QUER FAZER ISSO?")
        }

        reactions = Bundle.main.decodeJSON("reactions_data.json")
        reactions.sort(by: { $0.position < $1.position })

        for i in 0...(reactions.count-1) {
            reactions[i].lastUpdate = Date.now.toISO8601String()
            if let reactionSounds = reactions[i].sounds, !reactionSounds.isEmpty {
                for j in 0...(reactions[i].sounds!.count-1) {
                    reactions[i].sounds![j].dateAdded = Date.now.toISO8601String()
                }
            }
        }

        sendAll()
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

    private func moveUp(selectedID: ReactionSoundForDisplay.ID?) {
        guard let selectedID = selectedID,
              let index = reactions.firstIndex(where: { $0.id == selectedID }),
              index > 0 else { return }
        reactions.swapAt(index, index - 1)
        updatePositions()
    }

    private func moveDown(selectedID: ReactionSoundForDisplay.ID?) {
        guard let selectedID = selectedID,
              let index = reactions.firstIndex(where: { $0.id == selectedID }),
              index < reactions.count - 1 else { return }
        reactions.swapAt(index, index + 1)
        updatePositions()
    }

    private func updatePositions() {
        for (index, _) in reactions.enumerated() {
            reactions[index].position = index + 1
        }
    }
}

#Preview {
    ReactionsCRUDView()
}
