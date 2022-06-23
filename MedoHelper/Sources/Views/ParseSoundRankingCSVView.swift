import SwiftUI

struct ParseSoundRankingCSVView: View {

    @State private var filePath: String = "/Users/rafaelschmitt/Projetos/MedoDelirioBrasilia/MedoDelirioBrasilia/Resources/sound_data.json"
    @State private var showAlert: Bool = false
    @State private var showFileImporterModal: Bool = false
    @State private var importedFileName: String = ""
    
    var body: some View {
        VStack {
            TextField("Arquivo JSON de sons", text: $filePath)
                .padding()
            
            Button("Selecionar arquivo CSV...") {
                //let pasteboard = NSPasteboard.general
                //pasteboard.clearContents()
                //pasteboard.setString(generateSoundJSON(), forType: .string)
                //sound.successMessage = "JSON de '\(sound.title)' copiado!"
                showAlert = true
            }
            
            Text(importedFileName)
            
            Button("Interpretar") {
                //let pasteboard = NSPasteboard.general
                //pasteboard.clearContents()
                //pasteboard.setString(generateSoundJSON(), forType: .string)
                //sound.successMessage = "JSON de '\(sound.title)' copiado!"
                showAlert = true
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Teste"), message: Text("Teste"), dismissButton: .default(Text("OK")))
            }
        }
        .fileImporter(
            isPresented: $showFileImporterModal,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            do {
                guard let selectedFile: URL = try result.get().first else { return }
                guard let conteudoArquivo = String(data: try Data(contentsOf: selectedFile), encoding: .utf8) else { return }
                
                //CSVParser.parse(file: conteudoArquivo, indices: indices!)
                
                importedFileName = selectedFile.lastPathComponent
            } catch {
                // TODO: Implementar alert para exibir mensagem de erro.
            }
        }
    }

}

struct ParseSoundRankingCSVView_Previews: PreviewProvider {

    static var previews: some View {
        ParseSoundRankingCSVView()
    }

}
