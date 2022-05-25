import SwiftUI

struct SoundView: View {

    @Binding var sound: Sound
    
    var body: some View {
        VStack {            
            TextField("Título do Som", text: $sound.title)
                .padding()
            
            TextField("Descrição do Som", text: $sound.description)
                .padding()
            
            TextField("Nome do arquivo (sem .mp3)", text: $sound.filename)
                .padding()
            
            DatePicker("Data de adição", selection: $sound.dateAdded, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .padding()
            
            Toggle("É ofensivo", isOn: $sound.isOffensive)
                .padding()
            
            Button("Gerar JSON Som") {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(generateSoundJSON(), forType: .string)
                sound.successMessage = "JSON de X copiado!"
            }

            Text(sound.successMessage)
                .padding()
        }
    }
    
    func generateSoundJSON() -> String {
        let soundId = UUID().uuidString
        
        var dateString = ""
        let components = sound.dateAdded.get(.day, .month, .year)
        if let day = components.day, let month = components.month, let year = components.year {
            let formattedMonth = String(format: "%02d", month)
            let formattedDay = String(format: "%02d", day)
            
            dateString = "\(year)-\(formattedMonth)-\(formattedDay)"
        }
        
        return ",\n{\n\t\"id\": \"\(soundId)\",\n\t\"title\": \"\(sound.title)\",\n\t\"authorId\": \"\(authorId)\",\n\t\"description\": \"\(sound.description)\",\n\t\"filename\": \"\(sound.filename).mp3\",\n\t\"dateAdded\": \"\(dateString)T00:00:00Z\",\n\t\"isOffensive\": \(sound.isOffensive ? "true": "false")\n}"
    }

}

struct SoundView_Previews: PreviewProvider {

    static var previews: some View {
        SoundView(sound: .constant(Sound(title: "", description: "", filename: "", dateAdded: Date(), isOffensive: false, successMessage: "...")))
    }

}
