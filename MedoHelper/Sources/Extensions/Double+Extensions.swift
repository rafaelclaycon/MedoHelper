//
//  Double+Extensions.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 05/05/23.
//

import Foundation

extension Double {
    
    func asString() -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: self) ?? ""
    }
}
