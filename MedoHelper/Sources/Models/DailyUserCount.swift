//
//  DailyUserCount.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 23/12/25.
//

import Foundation

struct DailyUserCount: Codable, Identifiable, Equatable {
    let id: String // date string
    let date: String
    let count: Int
    
    var dateValue: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }
}


