import Foundation

struct Author: Hashable, Codable, Identifiable, CustomDebugStringConvertible {

    var id: String
    var name: String
    var photo: String?
    var description: String?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        photo: String? = nil,
        description: String? = nil
    ) {
        self.id = id
        self.name = name
        self.photo = photo
        self.description = description
    }
    
    var debugDescription: String {
        return self.name
    }
}
