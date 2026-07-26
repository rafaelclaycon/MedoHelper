//
//  ServerContentCRUDView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 26/07/26.
//

import SwiftUI

/// Unified "Conteúdo" tab listing both sounds and songs in a single table.
struct ServerContentCRUDView: View {

    @State private var editingItem: ContentListItem? = nil

    @State private var showAddAlreadyOnAppSheet = false
    @State private var addAlreadyOnAppContentType: ContentType = .sound
    @State private var fixedSoundData: [Sound]? = nil
    @State private var fixedSongData: [Song]? = nil

    @State private var items: [ContentListItem] = []
    @State private var selectedItem: ContentListItem.ID?
    @State private var showLoadingView: Bool = false
    @State private var showEditSheet = false
    @State private var showReplaceSheet = false
    @State private var searchText = ""

    @StateObject var replaceSoundEnv = ReplaceSoundHelper()

    private let contentRepository: ContentRepositoryProtocol = ContentRepository()

    // Alert
    @State private var showAlert = false
    @State private var alertType: AlertType = .singleOptionInformative
    @State private var alertErrorMessage: String = ""

    // MARK: - Computed Properties

    private var selectedItemTitle: String {
        guard let selectedItem else { return "" }
        return getItem(withID: selectedItem)?.title ?? ""
    }

    private var searchResults: [ContentListItem] {
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { item in
                item.title.preparedForComparison().contains(searchText.preparedForComparison())
            }
        }
    }

    // MARK: - View Body

    var body: some View {
        ZStack {
            VStack {
                Table(searchResults, selection: $selectedItem) {
                    TableColumn("Título", value: \.title)
                    TableColumn("Tipo", value: \.typeDisplayName)
                        .width(min: 50, max: 80)
                    TableColumn("Adicionado em") { item in
                        Text(item.dateAdded?.displayString ?? "")
                    }
                    .width(min: 50, max: 100)
                    TableColumn("Duração") { item in
                        Text("\(item.duration.asString())")
                    }
                    .width(min: 50, max: 100)
                }.contextMenu(forSelectionType: ContentListItem.ID.self) { selectedIds in
                    Section {
                        Button("Editar Metadados") {
                            guard let selectedId = selectedIds.first else { return }
                            editItem(withId: selectedId)
                        }

                        if let selectedId = selectedIds.first, getItem(withID: selectedId)?.contentType == .sound {
                            Button("Substituir Arquivo do Som") {
                                replaceSoundFile(withId: selectedId)
                            }
                        }
                    }

                    Section {
                        Button("Remover") {
                            guard let selectedId = selectedIds.first else { return }
                            selectedItem = selectedId
                            alertType = .twoOptionsOneDelete
                            showAlert = true
                        }
                    }
                } primaryAction: { selectedIds in
                    guard let selectedId = selectedIds.first else { return }
                    editItem(withId: selectedId)
                }
                .searchable(text: $searchText)

                HStack(spacing: 10) {
                    Button {
                        self.editingItem = nil
                        showEditSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .sheet(isPresented: $showEditSheet) {
                        AddOrEditContentView(
                            item: editingItem,
                            contentRepository: contentRepository
                        )
                        .frame(minWidth: 800, minHeight: 500)
                    }
                    .sheet(isPresented: $showReplaceSheet) {
                        ReplaceSoundFileOnServerView()
                            .frame(minWidth: 800, minHeight: 300)
                            .environmentObject(replaceSoundEnv)
                    }

                    Button {
                        alertType = .twoOptionsOneDelete
                        showAlert = true
                    } label: {
                        Image(systemName: "minus")
                    }
                    .alert(isPresented: $showAlert) {
                        switch alertType {
                        case .singleOptionInformative:
                            return Alert(
                                title: Text("Item Removido Com Sucesso"),
                                message: Text("\"\(selectedItemTitle)\" foi marcado como removido no servidor e a mudança será propagada para todos os clientes na próxima sincronização."),
                                dismissButton: .cancel(Text("OK")) {
                                    fetchItems()
                                }
                            )

                        case .twoOptionsOneDelete:
                            return Alert(title: Text("Remover \"\(selectedItemTitle)\""), message: Text("Tem certeza de que deseja remover \"\(selectedItemTitle)\"? A mudança será sincronizada com o servidor e propagada para todos os clientes na próxima sincronização."), primaryButton: .destructive(Text("Remover"), action: {
                                guard let selectedItem, let item = getItem(withID: selectedItem) else { return }
                                removeItem(item)
                            }), secondaryButton: .cancel(Text("Cancelar")))

                        default:
                            return Alert(title: Text("Houve um Problema Ao Tentar Marcar o Item como Removido"), message: Text(alertErrorMessage), dismissButton: .cancel(Text("OK")))
                        }
                    }

                    Spacer()

                    Button("Copiar títulos") {
                        copyTitlesToClipboard()
                    }

                    Button("Enviar Sons Já no App") {
                        showMoveDataSheet(for: .sound)
                    }

                    Button("Enviar Músicas Já no App") {
                        showMoveDataSheet(for: .song)
                    }

                    Text("\(items.count.formattedString) itens")
                }
                .sheet(isPresented: $showAddAlreadyOnAppSheet) {
                    if addAlreadyOnAppContentType == .sound, let fixedSoundData {
                        MoveDataToServerView(isBeingShown: $showAddAlreadyOnAppSheet,
                                             data: fixedSoundData,
                                             chunkSize: 10,
                                             endpointEnding: "v3/import-sounds/\(Secrets.assetOperationPassword)")
                            .frame(minWidth: 800, minHeight: 500)
                    } else if let fixedSongData {
                        MoveDataToServerView(isBeingShown: $showAddAlreadyOnAppSheet,
                                             data: fixedSongData,
                                             chunkSize: 10,
                                             endpointEnding: "v3/import-songs/\(Secrets.assetOperationPassword)")
                            .frame(minWidth: 800, minHeight: 500)
                    }
                }
            }
            .navigationTitle("Conteúdo no Servidor")
            .padding()
            .onAppear {
                fetchItems()
            }
            .onChange(of: showAddAlreadyOnAppSheet) { if !$0 { fetchItems() } }
            .onChange(of: showEditSheet) { if !$0 { fetchItems() } }

            if showLoadingView {
                LoadingView()
            }
        }
    }

    // MARK: - Functions

    private func fetchItems() {
        Task {
            await MainActor.run {
                showLoadingView = true
            }

            do {
                let soundsUrl = URL(string: serverPath + "v3/all-sounds")!
                let songsUrl = URL(string: serverPath + "v3/all-songs")!

                async let fetchedSounds: [Sound] = APIClient().getArray(from: soundsUrl)
                async let fetchedSongs: [Song] = APIClient().getArray(from: songsUrl)

                let (sounds, songs) = try await (fetchedSounds, fetchedSongs)

                var combined: [ContentListItem] = sounds.map { .sound($0) } + songs.map { .song($0) }
                combined.sort(by: { $0.dateAdded ?? Date() > $1.dateAdded ?? Date() })

                self.items = combined
            } catch {
                print(error)
            }

            await MainActor.run {
                showLoadingView = false
            }
        }
    }

    private func getItem(withID id: String) -> ContentListItem? {
        items.first { $0.id == id }
    }

    private func editItem(withId itemId: String) {
        guard let item = getItem(withID: itemId) else { return }
        self.editingItem = item
        showEditSheet = true
    }

    private func replaceSoundFile(withId itemId: String) {
        guard let item = getItem(withID: itemId), let sound = item.sound else { return }
        replaceSoundEnv.sound = sound

        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
            showReplaceSheet = true
        }
    }

    private func removeItem(_ item: ContentListItem) {
        Task {
            do {
                try await contentRepository.delete(contentId: item.id, contentType: item.contentType)
                alertType = .singleOptionInformative
                showAlert = true
            } catch {
                alertType = .singleOptionError
                alertErrorMessage = error.localizedDescription
                showAlert = true
            }
        }
    }

    private func showMoveDataSheet(for contentType: ContentType) {
        Task {
            addAlreadyOnAppContentType = contentType
            if contentType == .sound {
                fixedSoundData = Bundle.main.decodeJSON("sound_data.json")
                fixedSoundData?.sort(by: { $0.dateAdded ?? Date() > $1.dateAdded ?? Date() })
            } else {
                fixedSongData = Bundle.main.decodeJSON("song_data.json")
                fixedSongData?.sort(by: { $0.dateAdded ?? Date() > $1.dateAdded ?? Date() })
            }
            showAddAlreadyOnAppSheet = true
        }
    }

    private func copyTitlesToClipboard() {
        #if canImport(AppKit)
        let titles = items.map { $0.title }.joined(separator: "\n")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(titles, forType: .string)
        #endif
    }
}

#Preview {
    ServerContentCRUDView()
}
