//
//  Int+Extensions.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 08/05/23.
//

import Foundation

extension Int {
    
    var formattedString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? ""
    }
}
