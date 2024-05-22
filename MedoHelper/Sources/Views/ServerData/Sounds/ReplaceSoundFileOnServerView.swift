//
//  ReplaceFileOnServerView.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 26/05/23.
//

import SwiftUI

struct ReplaceSoundFileOnServerView: View {

    @Binding var isBeingShown: Bool
    private var sound: Sound
    
    @State private var showFilePicker = false
    @State private var selectedFile: URL? = nil
    
    // Alert
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var alertType: AlertType = .singleOptionError
    
    // Progress View
    @State private var showSendProgress = false
    @State private var progressAmount = 0.0
    @State private var modalMessage = ""
    
    private var filename: String {
        return selectedFile?.lastPathComponent ?? ""
    }

    init(
        isBeingShown: Binding<Bool>,
        sound: Sound? = nil
    ) {
        _isBeingShown = isBeingShown
        self.sound = sound ?? Sound(title: "")
    }
    
    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Text("Substituir Arquivo do Som \"\(sound.title)\"")
                    .font(.title)
                    .bold()
                
                Spacer()
            }
            
            Text("1. Selecione o arquivo modificado.\n2. Clique em **Gerar novo arquivo** para renomeá-lo com o UUID do conteúdo.\n3. Suba o novo arquivo para o servidor via FileZilla.\n4. Clique em **Submeter mudança de duração** para criar um novo UpdateEvent no servidor.")
            
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
                    generateNewFile()
                } label: {
                    Text("Gerar novo arquivo")
                        .padding(.horizontal)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedFile == nil)
            }
        }
        .padding(.all, 26)
        .sheet(isPresented: $showSendProgress) {
            SendingProgressView(isBeingShown: $showSendProgress, message: $modalMessage, currentAmount: $progressAmount, totalAmount: .constant(1))
        }
        .alert(isPresented: $showingAlert) {
            switch alertType {
            case .twoOptionsOneContinue:
                return Alert(title: Text("Aguardando para Criar os Eventos de Atualização"), message: Text("Mova o arquivo \"\(sound.id).mp3\" para o servidor antes de criar o UpdateEvent de arquivo alterado."), primaryButton: .default(Text("Continuar"), action: {
                    createUpdateEvents()
                }), secondaryButton: .cancel(Text("Cancelar")))
                
            case .singleOptionInformative:
                return Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK"), action: {
                    isBeingShown = false
                }))
                
            default:
                return Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func generateNewFile() {
        Task {
            guard let fileURL = selectedFile else { return }
            
            showSendProgress = true
            modalMessage = "Renomeando Arquivo..."
            
            let documentsFolder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            do {
                try renameFile(from: fileURL, with: "\(sound.id).mp3", saveTo: documentsFolder)
            } catch {
                print(error)
                alertTitle = "Falha Ao Renomear Arquivo"
                alertMessage = error.localizedDescription
                alertType = .singleOptionError
                showSendProgress = false
                return showingAlert = true
            }
            
            FileHelper.openFolderInFinder(documentsFolder)
            
            progressAmount = 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(600)) {
                showSendProgress = false
                alertType = .twoOptionsOneContinue
                showingAlert = true
            }
        }
    }
    
    private func createUpdateEvents() {
        Task {
            do {
                try await createFileUpdatedUpdateEvent()
            } catch {
                print(error)
                alertTitle = "Falha Ao Criar Evento de Atualização de Atualização de Arquivo"
                alertMessage = error.localizedDescription
                alertType = .singleOptionError
                showSendProgress = false
                return showingAlert = true
            }
            
            do {
                try await createDurationChangedUpdateEvent()
            } catch {
                print(error)
                alertTitle = "Falha Ao Criar Evento de Atualização de Duração"
                alertMessage = error.localizedDescription
                alertType = .singleOptionError
                showSendProgress = false
                return showingAlert = true
            }
            
            alertTitle = "Arquivo Atualizado com Sucesso"
            alertMessage = ""
            alertType = .singleOptionInformative
            return showingAlert = true
        }
    }
    
    private func createFileUpdatedUpdateEvent() async throws {
        let url = URL(string: serverPath + "v3/update-content-file/sound/\(sound.id)/\(assetOperationPassword)")!
        _ = try await NetworkRabbit.post(data: nil as String?, to: url)
    }
    
    private func createDurationChangedUpdateEvent() async throws {
        let url = URL(string: serverPath + "v3/update-content/\(assetOperationPassword)")!
        
        guard let fileURL = selectedFile else { throw ReplaceSoundFileOnServerViewError.couldNotGetFile }
        guard let newDuration = await FileHelper.getDuration(of: fileURL) else { throw ReplaceSoundFileOnServerViewError.unableToCalculateNewDuration }
        
        let content = MedoContent(sound: sound, authorId: sound.authorId, duration: newDuration)
        let _: Bool = try await NetworkRabbit.put(in: url, data: content)
    }
    
    private func renameFile(from fileURL: URL, with filename: String, saveTo destinationURL: URL) throws {
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: destinationURL.appending(path: filename).path(percentEncoded: false)) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        try FileHelper.copyAndRenameFile(from: fileURL, to: destinationURL, with: filename)
    }
}

struct ReplaceSoundFileOnServerView_Previews: PreviewProvider {
    
    static var previews: some View {
        ReplaceSoundFileOnServerView(isBeingShown: .constant(true), sound: Sound(title: ""))
    }
}

enum ReplaceSoundFileOnServerViewError: Error {
    
    case couldNotGetFile, unableToCalculateNewDuration
}

extension ReplaceSoundFileOnServerViewError: LocalizedError {
    
    public var errorDescription: String? {
        switch self {
        case .couldNotGetFile:
            return NSLocalizedString("Não conseguiu obter o arquivo do som.", comment: "")
        case .unableToCalculateNewDuration:
            return NSLocalizedString("Não conseguiu calcular a nova duração.", comment: "")
        }
    }
}
