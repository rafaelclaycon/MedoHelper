import Foundation

struct Author: Hashable, Codable, Identifiable {

    let id: String
    let name: String
    let photo: String?
    let description: String?
    
//    private enum CodingKeys: String, CodingKey {
//        case authorId = "id"
//        case name
//        case photo
//        case description
//    }
    
//    var id: String {
//        return authorId
//    }
}
