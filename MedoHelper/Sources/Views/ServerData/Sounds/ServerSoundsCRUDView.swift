//
//  ServerSoundsCRUDView.swift
//  MedoHelper
//
//  Created by Rafael Claycon Schmitt on 30/04/23.
//

import SwiftUI

struct ServerSoundsCRUDView: View {

    @State private var sound: Sound? = nil

    @State private var showAddAlreadyOnAppSheet = false
    @State private var fixedData: [Sound]? = nil

    @State private var sounds: [Sound] = []
    @State private var selectedItem: Sound.ID?
    @State private var showLoadingView: Bool = false
    @State private var showEditSheet = false
    @State private var showReplaceSheet = false
    @State private var searchText = ""

    @StateObject var replaceSoundEnv = ReplaceSoundHelper()

    // Alert
    @State private var showAlert = false
    @State private var alertType: AlertType = .singleOptionInformative
    @State private var alertErrorMessage: String = ""

    // MARK: - Computed Properties

    private var selectedSoundTitle: String {
        guard let selectedSound = selectedItem else { return "" }
        guard let sound = getSound(withID: selectedSound, from: sounds) else { return "" }
        return sound.title
    }

    private var searchResults: [Sound] {
        if searchText.isEmpty {
            return sounds
        } else {
            return sounds.filter { sound in
                let normalizedAuthorName = sound.title.preparedForComparison()
                return normalizedAuthorName.contains(searchText.preparedForComparison())
            }
        }
    }

    // MARK: - View Body

    var body: some View {
        ZStack {
            VStack {
                Table(searchResults, selection: $selectedItem) {
                    TableColumn("Título", value: \.title)
                    TableColumn("Adicionado em") { sound in
                        Text(sound.dateAdded?.toScreenString() ?? "")
                    }
                    .width(min: 50, max: 100)
                    TableColumn("Duração") { sound in
                        Text("\(sound.duration.asString())")
                    }
                    .width(min: 50, max: 100)
                }.contextMenu(forSelectionType: Sound.ID.self) { items in
                    Section {
                        Button("Editar Metadados do Som") {
                            guard let selectedItemId = items.first else { return }
                            editSound(withId: selectedItemId)
                        }

                        Button("Substituir Arquivo do Som") {
                            guard let selectedItemId = items.first else { return }
                            replaceSoundFile(withId: selectedItemId)
                        }
                    }

                    Section {
                        Button("Remover Som") {
                            guard let selectedItemId = items.first else { return }
                            selectedItem = selectedItemId
                            alertType = .twoOptionsOneDelete
                            showAlert = true
                        }
                    }
                } primaryAction: { items in
                    guard let selectedItemId = items.first else { return }
                    editSound(withId: selectedItemId)
                }
                .searchable(text: $searchText)
                
                HStack(spacing: 10) {
                    Button {
                        self.sound = nil
                        showEditSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .sheet(isPresented: $showEditSheet) {
                        EditSoundOnServerView(sound: sound)
                            .frame(minWidth: 800, minHeight: 500)
                    }
                    .sheet(isPresented: $showReplaceSheet) {
                        ReplaceSoundFileOnServerView()
                            .frame(minWidth: 800, minHeight: 300)
                            .environmentObject(replaceSoundEnv)
                    }
                    
                    Button {
                        print((selectedItem ?? "") as String)
                        alertType = .twoOptionsOneDelete
                        showAlert = true
                    } label: {
                        Image(systemName: "minus")
                    }
                    .alert(isPresented: $showAlert) {
                        switch alertType {
                        case .singleOptionInformative:
                            return Alert(
                                title: Text("Som Removido Com Sucesso"),
                                message: Text("O som \"\(selectedSoundTitle)\" foi marcado como removido no servidor e a mudança será propagada para todos os clientes na próxima sincronização."),
                                dismissButton: .cancel(Text("OK")) {
                                    fetchSounds()
                                }
                            )

                        case .twoOptionsOneDelete:
                            return Alert(title: Text("Remover \"\(selectedSoundTitle)\""), message: Text("Tem certeza de que deseja remover o som \"\(selectedSoundTitle)\"? A mudança será sincronizada com o servidor e propagada para todos os clientes na próxima sincronização."), primaryButton: .destructive(Text("Remover"), action: {
                                guard let selectedItem else { return }
                                removeSound(withId: selectedItem)
                            }), secondaryButton: .cancel(Text("Cancelar")))
                            
                        default:
                            return Alert(title: Text("Houve um Problema Ao Tentar Marcar o Som como Removido"), message: Text(alertErrorMessage), dismissButton: .cancel(Text("OK")))
                        }
                    }
                    
                    Spacer()

                    Button("Copiar títulos") {
                        copyTitlesToClipboard()
                    }

                    Button("Enviar Sons Já no App") {
                        showMoveDataSheet()
                    }
                    .sheet(isPresented: $showAddAlreadyOnAppSheet) {
                        MoveDataToServerView(isBeingShown: $showAddAlreadyOnAppSheet,
                                             data: fixedData!,
                                             chunkSize: 10,
                                             endpointEnding: "v3/import-sounds/\(assetOperationPassword)")
                            .frame(minWidth: 800, minHeight: 500)
                    }
                    
                    Text("\(sounds.count.formattedString) itens")
                }
            }
            .navigationTitle("Sons no Servidor")
            .padding()
            .onAppear {
                fetchSounds()
            }
            .onChange(of: showAddAlreadyOnAppSheet) { if !$0 { fetchSounds() } }
            .onChange(of: showEditSheet) { if !$0 { fetchSounds() } }

            if showLoadingView {
                LoadingView()
            }
        }
    }

    // MARK: - Functions

    private func fetchSounds() {
        Task {
            await MainActor.run {
                showLoadingView = true
            }
            
            do {
                let url = URL(string: serverPath + "v3/all-sounds")!
                
                var fetchedSounds: [Sound] = try await NetworkRabbit.getArray(from: url)
//                for i in 0...(allSounds.count - 1) {
//                    allSounds[i].authorName = authorData.first(where: { $0.id == allSounds[i].authorId })?.name ?? Shared.unknownAuthor
//                }
                
                fetchedSounds.sort(by: { $0.dateAdded ?? Date() > $1.dateAdded ?? Date() })
                
                self.sounds = fetchedSounds
            } catch {
                print(error)
            }
            
            await MainActor.run {
                showLoadingView = false
            }
        }
    }
    
    private func getSound(withID id: String, from sounds: [Sound]) -> Sound? {
        for sound in sounds {
            if sound.id == id {
                return sound
            }
        }
        return nil
    }
    
    private func editSound(withId itemId: String) {
        guard let item = getSound(withID: itemId, from: sounds) else { return }
        self.sound = item
        showEditSheet = true
    }
    
    private func replaceSoundFile(withId itemId: String) {
        guard let item = getSound(withID: itemId, from: sounds) else { return }
        replaceSoundEnv.sound = item

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
            showReplaceSheet = true
        }
    }
    
    private func removeSound(withId soundId: String) {
        Task {
            do {
                let url = URL(string: serverPath + "v3/sound/\(soundId)/\(assetOperationPassword)")!
                let _ = try await NetworkRabbit.delete(in: url, data: nil as String?)
                alertType = .singleOptionInformative
                showAlert = true
            } catch {
                alertType = .singleOptionError
                alertErrorMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
    
    private func showMoveDataSheet() {
        Task {
            fixedData = Bundle.main.decodeJSON("sound_data.json")
            fixedData?.sort(by: { $0.dateAdded ?? Date() > $1.dateAdded ?? Date() })
            showAddAlreadyOnAppSheet = true
        }
    }

    private func copyTitlesToClipboard() {
        let titles = sounds.map { $0.title }.joined(separator: "\n")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(titles, forType: .string)
    }
}

#Preview {
    ServerSoundsCRUDView()
}
