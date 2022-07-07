import Foundation

class CSVParser {

    static func parseToRank(string: String, using titleSource: [Sound], and authorNameSource: [Author]) -> [RankItem]? {
        guard string.isEmpty == false else {
            return nil
        }
        
        let lines = string.split(separator: "\n")
        
        var result = [RankItem]()
        
        // Inicializa variáveis locais de apoio
        var field: Int = 0
        
        var soundId: String = ""
        var count: String = ""
        
        for line in lines {
            let columns = line.split(separator: ",", omittingEmptySubsequences: false)
            
            field = 0
            
            for column in columns {
                if field == 0 {
                    soundId = String(column)
                } else if field == 1 {
                    count = String(column)
                }
                
                field += 1
            }
            
            if let sound = titleSource.first(where: {$0.id == soundId}) {
                if let author = authorNameSource.first(where: {$0.id == sound.authorId}) {
                    result.append(RankItem(soundId: soundId, title: sound.title, authorName: author.name, shareCount: Int(count) ?? 0))
                } else {
                    result.append(RankItem(soundId: soundId, title: sound.title, authorName: "", shareCount: Int(count) ?? 0))
                }
                
            } else {
                result.append(RankItem(soundId: soundId, title: "", authorName: "", shareCount: Int(count) ?? 0))
            }
        }
        
        return result
    }

}
