//
//  ExternalLink.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 26/03/24.
//

import Foundation

struct ExternalLink: Hashable, Codable, Identifiable {

    var id: String
    var symbol: String
    var title: String
    var color: String
    var link: String

    init(
        id: String = UUID().uuidString,
        symbol: String = "",
        title: String = "",
        color: String = "",
        link: String = ""
    ) {
        self.id = id
        self.symbol = symbol
        self.title = title
        self.color = color
        self.link = link
    }
}

struct SimplifiedExternalLink: Codable {

    var symbol: String
    var title: String
    var color: String
    var link: String
}

extension Array where Element == ExternalLink {

    func asJSONString() -> String? {
        guard self.count > 0 else {
            return nil
        }
        let simplifiedExternalLinks = self.map { SimplifiedExternalLink(symbol: $0.symbol, title: $0.title, color: $0.color, link: $0.link) }
        let jsonData = try? JSONEncoder().encode(simplifiedExternalLinks)
        if let jsonData = jsonData, let jsonString = String(data: jsonData, encoding: .utf8) {
            print(jsonString)
            return jsonString
        } else {
            return nil
        }
    }
}
