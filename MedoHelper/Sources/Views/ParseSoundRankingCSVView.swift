import SwiftUI

struct ParseSoundRankingCSVView: View {

    @State private var filePath: String = ""
    @State private var showAlert: Bool = false
    @State private var isImportingSoundsFile: Bool = false
    @State private var showFileImporterModal: Bool = false
    @State private var importedFileName: String = ""
    @State private var resultString: String = ""
    
    @State private var soundData: [Sound]? = nil
    @State private var globalFileContent: String = ""
    
    var body: some View {
        VStack {
            TextField("Arquivo JSON de sons", text: $filePath)
                .padding()
                .disabled(true)
            
            Button("Carregar sons") {
                isImportingSoundsFile = true
                showFileImporterModal = true
            }
            
            Text(soundData == nil ? "" : "\(soundData!.count) sons")
                .padding()
            
            Button("Selecionar arquivo CSV...") {
                showFileImporterModal = true
            }
            
            Text(importedFileName)
                .padding()
            
            HStack(spacing: 20) {
                Button("Interpretar") {
                    resultString = ""
                    guard let rank = CSVParser.parseToRank(string: globalFileContent, using: soundData!) else {
                        return showAlert = true
                    }
                    
                    for i in 0...(rank.count - 1) {
                        resultString.append("\(i + 1). \(rank[i].title)    \(rank[i].shareCount)\n")
                    }
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Não foi possível interpretar o arquivo de rank"), dismissButton: .default(Text("OK")))
                }
                
                Button("Copiar top 10") {
                    var localRankString = ""
                    guard let rank = CSVParser.parseToRank(string: globalFileContent, using: soundData!), rank.count >= 10 else {
                        print("Não tem 10 itens para fazer um top 10!")
                        return
                    }
                    
                    for i in 0...9 {
                        localRankString.append("\(i + 1). \(rank[i].title)\n")
                    }
                    
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(localRankString, forType: .string)
                }
            }
            
            ScrollView {
                Text(resultString)
                    .padding()
            }
        }
        .fileImporter(
            isPresented: $showFileImporterModal,
            allowedContentTypes: [.json,.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            do {
                if isImportingSoundsFile {
                    guard let selectedFile: URL = try result.get().first else { return }
                    
                    let tempSounds: [Sound] = JSONFileToData.load(selectedFile)
                    soundData = tempSounds
                    
                    filePath = selectedFile.absoluteString
                    isImportingSoundsFile = false
                } else {
                    guard let selectedFile: URL = try result.get().first else { return }
                    guard let fileContent = String(data: try Data(contentsOf: selectedFile), encoding: .utf8) else { return }
                    
                    globalFileContent = fileContent
                    
                    importedFileName = selectedFile.lastPathComponent
                }
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
