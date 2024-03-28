//
//  Color+.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 27/03/24.
//

import SwiftUI

extension Color {

    func toString() -> String {
        switch self {
        case .red:
            return "red"
        default:
            return "black"
        }
    }
}
