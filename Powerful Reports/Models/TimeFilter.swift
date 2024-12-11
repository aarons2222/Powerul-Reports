//
//  TimeFilter.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 11/12/2024.
//

import SwiftUI


enum TimeFilter: String, Codable, CaseIterable {
    case last3Months = "3 Months"
    case last6Months = "6 Months"
    case last12Months = "1 Year"
    

    
    var date: Date {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .last3Months:
            return calendar.date(byAdding: .month, value: -3, to: now)!
        case .last6Months:
            return calendar.date(byAdding: .month, value: -6, to: now)!
        case .last12Months:
            return calendar.date(byAdding: .month, value: -12, to: now)!
        }
    }
    
    var dateInterval: DateInterval {
        let now = Date()
        return DateInterval(start: date, end: now)
    }
}

