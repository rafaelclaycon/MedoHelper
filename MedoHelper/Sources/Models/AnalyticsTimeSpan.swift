//
//  AnalyticsTimeSpan.swift
//  MedoHelper
//
//  Created by Rafael Schmitt on 18/12/25.
//

import Foundation

enum AnalyticsTimeSpan: String, CaseIterable {
    case today = "Hoje"
    case lastWeek = "Última Semana"
    case last3Months = "3 Meses"
    case last6Months = "6 Meses"
    case lastYear = "1 Ano"
    case allTime = "Tudo"
    
    var startDate: Date {
        let calendar = Calendar.current
        switch self {
        case .today: return calendar.startOfDay(for: Date())
        case .lastWeek: return calendar.date(byAdding: .day, value: -7, to: Date())!
        case .last3Months: return calendar.date(byAdding: .month, value: -3, to: Date())!
        case .last6Months: return calendar.date(byAdding: .month, value: -6, to: Date())!
        case .lastYear: return calendar.date(byAdding: .year, value: -1, to: Date())!
        case .allTime: return Date(timeIntervalSince1970: 0)
        }
    }
    
    var startDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: startDate)
    }
    
    var displayTitle: String {
        switch self {
        case .today: return "Usuários Ativos Hoje"
        case .lastWeek: return "Usuários Ativos - Última Semana"
        case .last3Months: return "Usuários Ativos - 3 Meses"
        case .last6Months: return "Usuários Ativos - 6 Meses"
        case .lastYear: return "Usuários Ativos - 1 Ano"
        case .allTime: return "Usuários Ativos - Todo Período"
        }
    }
    
    var topSoundsTitle: String {
        switch self {
        case .today: return "Sons Mais Compartilhados Hoje"
        case .lastWeek: return "Sons Mais Compartilhados - Última Semana"
        case .last3Months: return "Sons Mais Compartilhados - 3 Meses"
        case .last6Months: return "Sons Mais Compartilhados - 6 Meses"
        case .lastYear: return "Sons Mais Compartilhados - 1 Ano"
        case .allTime: return "Sons Mais Compartilhados - Todo Período"
        }
    }
}

