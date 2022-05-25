import SwiftUI

struct SoundView: View {

    @State private var soundTitle: String = ""
    @State private var soundDescription: String = ""
    @State private var soundFilename: String = ""
    @State private var soundDateAdded: Date = Date()
    @State private var soundIsOffensive: Bool = false
    @State private var soundJSONCopied: String = "..."
    
    var body: some View {
        VStack {
            Button("Limpar tudo") {
                soundTitle = ""
                soundDescription = ""
                soundFilename = ""
                soundIsOffensive = false
            }
            
            TextField("Título do Som", text: $soundTitle)
                .padding()
            
            TextField("Descrição do Som", text: $soundDescription)
                .padding()
            
            TextField("Nome do arquivo (sem .mp3)", text: $soundFilename)
                .padding()
            
            DatePicker("Data de adição", selection: $soundDateAdded, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding()
            
            Toggle("É ofensivo", isOn: $soundIsOffensive)
                .padding()
            
            Button("Gerar JSON Som") {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(generateSoundJSON(), forType: .string)
                soundJSONCopied = "JSON de X copiado!"
            }

            Text(soundJSONCopied)
                .padding()
        }
    }
    
    func generateSoundJSON() -> String {
        let soundId = UUID().uuidString
        
        var dateString = ""
        let components = soundDateAdded.get(.day, .month, .year)
        if let day = components.day, let month = components.month, let year = components.year {
            let formattedMonth = String(format: "%02d", month)
            let formattedDay = String(format: "%02d", day)
            
            dateString = "\(year)-\(formattedMonth)-\(formattedDay)"
        }
        
        return ",\n{\n\t\"id\": \"\(soundId)\",\n\t\"title\": \"\(soundTitle)\",\n\t\"authorId\": \"\(authorId)\",\n\t\"description\": \"\(soundDescription)\",\n\t\"filename\": \"\(soundFilename).mp3\",\n\t\"dateAdded\": \"\(dateString)T00:00:00Z\",\n\t\"isOffensive\": \(soundIsOffensive ? "true": "false")\n}"
    }

}

struct SoundView_Previews: PreviewProvider {

    static var previews: some View {
        SoundView()
    }

}
