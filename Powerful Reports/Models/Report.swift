//
//  Models.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 17/11/2024.
//


import Foundation
import SwiftUI


struct Report: Identifiable, Codable, Hashable {
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
    
    // Hashable implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(date)
        hasher.combine(inspector)
        hasher.combine(localAuthority)
        hasher.combine(outcome)
        hasher.combine(previousInspection)
        hasher.combine(ratings)
        hasher.combine(referenceNumber)
        hasher.combine(themes)
        hasher.combine(typeOfProvision)
        hasher.combine(timestamp)
    }
    
    // Equatable implementation (required for Hashable)
    static func == (lhs: Report, rhs: Report) -> Bool {
        return lhs.id == rhs.id &&
            lhs.date == rhs.date &&
            lhs.inspector == rhs.inspector &&
            lhs.localAuthority == rhs.localAuthority &&
            lhs.outcome == rhs.outcome &&
            lhs.previousInspection == rhs.previousInspection &&
            lhs.ratings == rhs.ratings &&
            lhs.referenceNumber == rhs.referenceNumber &&
            lhs.themes == rhs.themes &&
            lhs.typeOfProvision == rhs.typeOfProvision &&
            lhs.timestamp == rhs.timestamp
    }
}




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






