import Foundation

class JSONFileToData {

    static func load<T: Decodable>(_ fileUrl: URL) -> T {
        let data: Data
        
        do {
            data = try Data(contentsOf: fileUrl)
        } catch {
            fatalError("Não foi possível carregar \(fileUrl.absoluteString):\n\(error)")
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: data)
        } catch {
            fatalError("Não foi possível fazer o parse de \(fileUrl.absoluteString) como \(T.self):\n\(error)")
        }
    }

}
