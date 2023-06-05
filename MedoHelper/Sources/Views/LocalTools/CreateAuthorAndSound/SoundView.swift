import SwiftUI

struct SoundView: View {
    
    @State var sound = ProtoSound(title: "", description: "", filename: "", dateAdded: Date(), isOffensive: false, successMessage: "...")
    @State private var showFilePicker = false
    @State private var selectedFile: URL? = nil
    
    // Alert
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    private var filename: String {
        return selectedFile?.lastPathComponent ?? ""
    }

    private var hasAllNecessaryData: Bool {
        return sound.title != "" && sound.description != "" && selectedFile != nil
    }
    
    var body: some View {
        VStack(spacing: 30) {
            TextField("Título do Som", text: $sound.title)
            
            TextField("Descrição do Som", text: $sound.description)
            
            HStack(spacing: 30) {
                Button("Selecionar arquivo...") {
                    showFilePicker = true
                }
                .fileImporter(isPresented: $showFilePicker, allowedContentTypes: [.mp3]) { result in
                    do {
                        selectedFile = try result.get()
                        print(selectedFile as Any)
                    } catch {
                        alertTitle = "Erro ao Selecionar Arquivo"
                        alertMessage = error.localizedDescription
                        showingAlert = true
                    }
                }
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
                
                Text(filename)
            }
            
            DatePicker("Data de adição", selection: $sound.dateAdded, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
            
            Toggle("É ofensivo", isOn: $sound.isOffensive)
            
            Button("Copiar JSON do Som") {
                Task {
                    guard let soundJSONString = await createSoundJSON() else { return }
                    
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(soundJSONString, forType: .string)
                    
                    alertTitle = "JSON do Som Copiado com Sucesso"
                    alertMessage = ""
                    showingAlert = true
                }
            }
            .disabled(!hasAllNecessaryData)
        }
        .padding()
    }
    
    private func createSoundJSON() async -> String? {
        let soundId = UUID().uuidString
        
        var dateString = ""
        let components = sound.dateAdded.get(.day, .month, .year)
        if let day = components.day, let month = components.month, let year = components.year {
            let formattedMonth = String(format: "%02d", month)
            let formattedDay = String(format: "%02d", day)
            
            dateString = "\(year)-\(formattedMonth)-\(formattedDay)"
        }
        
        guard let fileURL = selectedFile else { return nil }
        guard let duration = await FileHelper.getDuration(of: fileURL) else { return nil }
        
        let formattedDuration = String(format: "%.2f", duration)
        
        return ",\n{\n\t\"id\": \"\(soundId)\",\n\t\"title\": \"\(sound.title)\",\n\t\"authorId\": \"\(authorId)\",\n\t\"description\": \"\(sound.description)\",\n\t\"filename\": \"\(filename)\",\n\t\"dateAdded\": \"\(dateString)T00:00:00Z\",\n\t\"duration\": \(formattedDuration),\n\t\"isOffensive\": \(sound.isOffensive ? "true": "false")\n}"
    }
}

struct SoundView_Previews: PreviewProvider {
    
    static var previews: some View {
        SoundView()
    }
}
