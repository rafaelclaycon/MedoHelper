import SwiftUI

struct ParseSoundRankingCSVView: View {
    
    enum ImportType {
        case sounds, authors, currentRanking, rankToRemove
    }
    
    @State private var filePath: String = ""
    @State private var showUnableToInterpretAlert: Bool = false
    @State private var showInterpretFileFirstAlert: Bool = false
    @State private var thingBeingImported: ImportType? = nil
    @State private var showFileImporterModal: Bool = false
    @State private var importedFileName: String = ""
    @State private var resultString: String = ""
    
    @State private var rank: [RankItem]? = nil
    
    @State private var soundData: [Sound]? = nil
    @State private var authorData: [Author]? = nil
    @State private var globalCurrentFileContent: String = ""
    @State private var globalToRemoveFileContent: String = ""
    @State private var soundsToRemoveFromCurrentRank: [Sound]? = nil
    
    private let buttonSpacing: CGFloat = 30
    
    var body: some View {
        VStack {
            TextField("Arquivo JSON de sons", text: $filePath)
                .padding()
                .disabled(true)
            
            HStack(spacing: buttonSpacing) {
                Button("Carregar sons") {
                    thingBeingImported = .sounds
                    showFileImporterModal = true
                }
                
                Button("Carregar autores") {
                    thingBeingImported = .authors
                    showFileImporterModal = true
                }
            }
            
            Text(soundData == nil ? "" : "\(soundData!.count) sons, \(authorData?.count ?? 0) autores")
                .padding()
            
            Button("Selecionar ranking atual...") {
                thingBeingImported = .currentRanking
                showFileImporterModal = true
            }
            
            Text(importedFileName)
                .padding()
            
            HStack(spacing: buttonSpacing) {
                Button("Interpretar") {
                    guard let localRank = CSVParser.parseToRank(string: globalCurrentFileContent, using: soundData!, and: authorData!) else {
                        return showUnableToInterpretAlert = true
                    }
                    self.rank = localRank
                }
                .alert(isPresented: $showUnableToInterpretAlert) {
                    Alert(title: Text("Não foi possível interpretar o arquivo de rank"), dismissButton: .default(Text("OK")))
                }
                
                Button("Imprimir") {
                    printRank()
                }
                .alert(isPresented: $showInterpretFileFirstAlert) {
                    Alert(title: Text("Primeiro Interprete um arquivo."), dismissButton: .default(Text("OK")))
                }
                
                Button("Selecionar contagem anterior...") {
                    thingBeingImported = .rankToRemove
                    showFileImporterModal = true
                }
                
                Button("Remover contagem anterior") {
                    guard let toRemoveRank = CSVParser.parseToRank(string: globalToRemoveFileContent, using: soundData!, and: authorData!) else {
                        print("Problem")
                        return
                    }
                    
                    for i in stride(from: 1, through: toRemoveRank.count - 1, by: 1) {
                        for j in stride(from: 1, through: self.rank!.count - 1, by: 1) {
                            if toRemoveRank[i].soundId == self.rank![j].soundId {
                                print("Vai analisar \(self.rank![j].title)")
                                self.rank![j].shareCount = self.rank![j].shareCount - toRemoveRank[i].shareCount
                            }
                        }
                    }
                    
                    self.rank?.sort(by: { $0.shareCount > $1.shareCount })
                }
                
                Button("Copiar top 10") {
                    var localRankString = ""
                    guard let rank = self.rank, rank.count >= 10 else {
                        print("Não tem 10 itens para fazer um top 10!")
                        return
                    }
                    
                    for i in 0...9 {
                        localRankString.append("\(i + 1). \(rank[i].authorName) - \(rank[i].title)\n")
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
                switch thingBeingImported {
                case .sounds:
                    guard let selectedFile: URL = try result.get().first else { return }
                    
                    let tempSounds: [Sound] = JSONFileToData.load(selectedFile)
                    soundData = tempSounds
                    
                    filePath = selectedFile.absoluteString
                    
                case .authors:
                    guard let selectedFile: URL = try result.get().first else { return }
                    
                    let tempAuthors: [Author] = JSONFileToData.load(selectedFile)
                    authorData = tempAuthors
                    
                    filePath = selectedFile.absoluteString
                    
                case .rankToRemove:
                    guard let selectedFile: URL = try result.get().first else { return }
                    guard let fileContent = String(data: try Data(contentsOf: selectedFile), encoding: .utf8) else { return }
                    
                    globalToRemoveFileContent = fileContent
                    
                default:
                    guard let selectedFile: URL = try result.get().first else { return }
                    guard let fileContent = String(data: try Data(contentsOf: selectedFile), encoding: .utf8) else { return }
                    
                    globalCurrentFileContent = fileContent
                    
                    importedFileName = selectedFile.lastPathComponent
                }
            } catch {
                // TODO: Implementar alert para exibir mensagem de erro.
                thingBeingImported = nil
            }
            thingBeingImported = nil
        }
        .padding()
    }
    
    private func printRank() {
        self.resultString = ""
        guard let rank = self.rank else {
            return showInterpretFileFirstAlert = true
        }
        
        for i in 0...(rank.count - 1) {
            self.resultString.append("\(i + 1). \(rank[i].authorName) - \(rank[i].title)    \(rank[i].shareCount)\n")
        }
    }
}

struct ParseSoundRankingCSVView_Previews: PreviewProvider {
    
    static var previews: some View {
        ParseSoundRankingCSVView()
    }
}
