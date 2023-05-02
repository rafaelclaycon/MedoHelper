//
//  MedoContent.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 30/04/23.
//

import Foundation

struct MedoContent: Codable {
    
    let title: String
    let authorId: String
    let description: String
    let contentFileId: String
    let creationDate: String
    let duration: Double
    let isOffensive: Bool
}
