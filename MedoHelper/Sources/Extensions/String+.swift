//
//  String+Extensions.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 02/05/23.
//

import Foundation
import SwiftUI

extension String {
    
    func removingDiacritics() -> String {
        return self.folding(options: .diacriticInsensitive, locale: .current)
    }
    
    func preparedForComparison() -> String {
        return self.lowercased().removingDiacritics()
    }
}

extension String {
    
    func lengthLimit(_ maxLength: Int) -> String {
        if self.count > maxLength {
            let endIndex = self.index(self.startIndex, offsetBy: maxLength)
            return String(self[..<endIndex])
        }
        return self
    }
}

extension String {

    var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let date = dateFormatter.date(from: self) {
            dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
            return dateFormatter.string(from: date)
        } else {
            return "Formato de data inválido"
        }
    }
}

extension String {

    func toColor() -> Color {
        switch self {
        case "red":
            return .red
        case "orange":
            return .orange
        case "yellow":
            return .yellow
        case "black":
            return .black
        case "blue":
            return .blue
        case "brown":
            return .brown
        case "gray":
            return .gray
        case "green":
            return .green
        case "purple":
            return .purple
        case "pink":
            return .pink
        case "mint":
            return .mint
        case "teal":
            return .teal
        case "cyan":
            return .cyan
        case "indigo":
            return .indigo
        default:
            return .white
        }
    }
}
