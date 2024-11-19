//
//  Models.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 17/11/2024.
//


import Foundation
import SwiftUI

// Main model for inspection reports
struct Report: Identifiable, Codable {
    let id: String
    let date: String
    let inspector: String
    let localAuthority: String
    let outcome: String
    let previousInspection: String
    let ratings: [Rating]
    let referenceNumber: String
    let themes: [Theme]
    let typeOfProvision: String
    let timestamp: Timestamp
}

// Model for ratings
struct Rating: Codable {
    let category: String
    let rating: String
}

// Model for themes identified in the inspection
struct Theme: Codable {
    let frequency: Int
    let topic: String
}

// Model for timestamp
struct Timestamp: Codable {
    let _seconds: Int64
    let _nanoseconds: Int64
    
    var date: Date {
        return Date(timeIntervalSince1970: TimeInterval(_seconds))
    }
}

// Extension to make InspectionReport more useful
extension Report {
    // Overall rating if available
    var overallRating: String? {
        ratings.first { $0.category == "Overall effectiveness" }?.rating
    }
    
    // Sorted themes by frequency
    var sortedThemes: [Theme] {
        themes.sorted { $0.frequency > $1.frequency }
    }
    
    // Most common themes (top 5)
    var mostCommonThemes: [Theme] {
        Array(sortedThemes.prefix(5))
    }
    
    // Format date string
    var formattedDate: String {
        guard !date.isEmpty else { return "No date" }
        return date
    }
}



// An enum for rating categories
enum RatingCategory: String, CaseIterable {
    case overallEffectiveness = "Overall effectiveness"
    case qualityOfEducation = "The quality of education"
    case behaviourAndAttitudes = "Behaviour and attitudes"
    case personalDevelopment = "Personal development"
    case leadershipAndManagement = "Leadership and management"
}

// An enum for possible rating values
enum RatingValue: String, CaseIterable {
    case outstanding = "Outstanding"
    case good = "Good"
    case requiresImprovement = "Requires improvement"
    case inadequate = "Inadequate"
    case none = ""
    
    var color: Color {
        switch self {
        case .outstanding: return .green
        case .good: return .blue
        case .requiresImprovement: return .orange
        case .inadequate: return .red
        case .none: return .gray
        }
    }
}






enum TimeFilter: String, Codable, CaseIterable {
    case last30Days = "30days"
    case last3Months = "3months"
    case last6Months = "6months"
    case last12Months = "12months"
    
    var title: String {
        switch self {
        case .last30Days: "30 Days"
        case .last3Months: "3 Months"
        case .last6Months: "6 Months"
        case .last12Months: "12 Months"
        }
    }
    
    var date: Date {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .last30Days:
            return calendar.date(byAdding: .day, value: -30, to: now)!
        case .last3Months:
            return calendar.date(byAdding: .month, value: -3, to: now)!
        case .last6Months:
            return calendar.date(byAdding: .month, value: -6, to: now)!
        case .last12Months:
            return calendar.date(byAdding: .month, value: -12, to: now)!
        }
    }
}
