//
//  String+Extensions.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 02/05/23.
//

import Foundation

extension String {
    
    func removingDiacritics() -> String {
        return self.folding(options: .diacriticInsensitive, locale: .current)
    }
    
    func preparedForComparison() -> String {
        return self.lowercased().removingDiacritics()
    }
}
