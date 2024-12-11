//
//  DummyData.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 25/11/2024.
//

import Foundation
import SwiftUI

struct DummyDataGenerator {
    // MARK: - Data Sources
    private let inspectors = [
        "Sarah Johnson", "Mark Wilson", "Emma Thompson", "David Brown", "Lisa Chen",
        "James Miller", "Rachel Adams", "Michael Zhang", "Karen White", "John Peters",
        "Patricia Lee", "Robert Taylor", "Susan Anderson", "Thomas Wright", "Helen Garcia",
        "Daniel Martinez", "Michelle Wong", "Christopher Lee", "Jennifer Smith", "Andrew Davis"
    ]
    
    private let localAuthorities = [
        "Kent", "Surrey", "Essex", "Hampshire", "Hertfordshire", "Suffolk",
        "Norfolk", "Berkshire", "Oxfordshire", "Buckinghamshire", "Cornwall",
        "Devon", "Dorset", "Somerset", "Wiltshire", "Greater London", "West Sussex", "East Sussex", "Cambridgeshire", "Northamptonshire",
        "Bedfordshire", "Lincolnshire", "Nottinghamshire", "Derbyshire", "Leicestershire",
        "Warwickshire", "Worcestershire", "Gloucestershire", "Bristol", "Bath and North East Somerset",
        "South Gloucestershire", "North Somerset", "Swindon", "Plymouth", "Torbay",
        "Bournemouth", "Poole", "Portsmouth", "Southampton", "Isle of Wight",
        "West Berkshire", "Reading", "Slough", "Windsor and Maidenhead", "Bracknell Forest",
        "Medway", "Brighton and Hove", "Milton Keynes", "Thurrock", "Southend-on-Sea",
        "Peterborough", "Luton", "Central Bedfordshire", "Northumberland", "Durham",
        "Tyne and Wear", "Cumbria", "Lancashire", "Merseyside", "Greater Manchester",
        "Cheshire", "Yorkshire", "Humberside", "Staffordshire", "Shropshire",
        "Herefordshire", "Rutland", "Camden", "Westminster", "Kensington and Chelsea",
        "Hammersmith and Fulham", "Wandsworth", "Lambeth", "Southwark", "Tower Hamlets"
    
    ]
    
    private let typeOfProvisions = [
        "Childcare on non-domestic premises",
        "Childminder",
        "Childcare on domestic premises",
    ]
    
    private let educationThemes = [
        "Children's Behaviour", "Personal Development", "Parent Partnerships",
        "Mathematical Development", "Physical Development", "Communication Skills",
        "Literacy Development", "Social Interaction", "Creative Expression",
        "Environmental Awareness", "Cultural Understanding", "Digital Skills",
        "Emotional Wellbeing", "Problem Solving", "Language Development", 
    ]
    
    private let complianceThemes = [
        "Safeguarding", "Staff Training", "Health and Safety", "Record Keeping",
        "Risk Assessment", "Documentation", "Policy Implementation", "Staff Qualifications",
        "First Aid Requirements", "Premises Safety", "Food Safety", "Emergency Procedures",
        "Child Protection", "GDPR Compliance", "Equipment Safety", "DBS Checks", "Insurance Coverage", "Fire Safety",
        "Evacuation Procedures", "Accident Reporting", "Medication Management",
        "Allergies Protocol", "Special Needs Provision", "Equal Opportunities",
        "Complaints Handling", "Parent Communication", "Staff Development",
        "Quality Assurance", "Environmental Health", "Building Maintenance",
        "Security Measures", "Access Control", "Visitor Protocols"
    ]
    
    // MARK: - Helper Functions
    private func randomItem<T>(_ array: [T]) -> T {
        array.randomElement()!
    }
    
    private func generateReferenceNumber() -> String {
        "EY\(Int.random(in: 100000...999999))"
    }
    
    private func getWeightedRating() -> RatingValue {
        let rand = Double.random(in: 0...1)
        switch rand {
        case 0..<0.15: return .outstanding
        case 0..<0.70: return .good
        case 0..<0.95: return .requiresImprovement
        default: return .inadequate
        }
    }
    
    private func generateTimestamp(for index: Int) -> Timestamp {
        let baseSeconds: Int64 = 1732028878 // November 19, 2024
        let dayInSeconds: Int64 = 86400
        let randomHourOffset = Int64.random(in: 0...(24 * 60 * 60))
        
        return Timestamp(
            _seconds: baseSeconds - (Int64(index / 10) * dayInSeconds) - randomHourOffset,
            _nanoseconds: 686000000 + Int64.random(in: 0...1000000)
        )
    }
    

        private func generateTimestamp(for index: Int, count: Int) -> Timestamp {
            // Calculate current date and date 12 months ago
            let calendar = Calendar.current
            let currentDate = Date()
            let twelveMonthsAgo = calendar.date(byAdding: .month, value: -12, to: currentDate)!
            
            // Calculate total time span in seconds
            let timeSpan = currentDate.timeIntervalSince(twelveMonthsAgo)
            
            // Distribute reports evenly across the time span
            // Use index to spread reports across the time range
            let intervalPerReport = timeSpan / Double(count)
            let offset = Double(index) * intervalPerReport
            
            // Add some randomization within the interval to avoid exact spacing
            let randomOffset = Double.random(in: 0...(intervalPerReport * 0.8))
            let timestamp = twelveMonthsAgo.addingTimeInterval(offset + randomOffset)
            
            return Timestamp(
                _seconds: Int64(timestamp.timeIntervalSince1970),
                _nanoseconds: Int64.random(in: 0...999999999)
            )
        }
        
        // Update the generate function to pass count to generateTimestamp
        static func generateDummyReports(count: Int = 100) -> [Report] {
            let generator = DummyDataGenerator()
            return (0..<count).map { index in
                let isComplianceCheck = Double.random(in: 0...1) < 0.4
                let timestamp = generator.generateTimestamp(for: index, count: count)
                
                let outcome: String
                let previousInspection: String
                let ratings: [Rating]
                
                if isComplianceCheck {
                    // For compliance checks, ensure previous inspection matches the Met/Not Met pattern
                    let isCurrentMet = Double.random(in: 0...1) < 0.8
                    let isPreviousMet = Double.random(in: 0...1) < 0.7
                    outcome = isCurrentMet ? RatingValue.met.rawValue : RatingValue.notmet.rawValue
                    previousInspection = isPreviousMet ? RatingValue.met.rawValue : RatingValue.notmet.rawValue
                    ratings = []
                } else {
                    // Regular inspections have ratings and no met/not met outcome
                    outcome = RatingValue.none.rawValue
                    ratings = generator.generateRatings(includeRatings: true)
                    // Previous inspection should be a standard rating for regular inspections
                    let previousRating = Double.random(in: 0...1) < 0.7 ? RatingValue.good.rawValue : RatingValue.requiresImprovement.rawValue
                    previousInspection = previousRating
                }
                
                return Report(
                    id: String(index + 1),
                    date: generator.formatDate(from: timestamp),
                    inspector: generator.randomItem(generator.inspectors),
                    localAuthority: generator.randomItem(generator.localAuthorities),
                    outcome: outcome,
                    previousInspection: previousInspection,
                    ratings: ratings,
                    referenceNumber: generator.generateReferenceNumber(),
                    themes: generator.generateThemes(isCompliance: isComplianceCheck),
                    typeOfProvision: generator.randomItem(generator.typeOfProvisions),
                    timestamp: timestamp
                )
            }.sorted { $0.timestamp.date > $1.timestamp.date }
        }
    
    
    private func generateRatings(includeRatings: Bool) -> [Rating] {
        guard includeRatings else { return [] }
        
        let mainRating = getWeightedRating()
        return RatingCategory.allCases.map { category in
            // All ratings should be standard grades (Outstanding/Good/Requires Improvement/Inadequate)
            // Never include Met/Not Met in ratings
            if category == .overallEffectiveness {
                return Rating(category: category.rawValue, rating: mainRating.rawValue)
            } else {
                // Ensure other ratings are within one level of the main rating
                let currentIndex = RatingValue.allCases.firstIndex(of: mainRating)!
                let possibleRange = max(0, currentIndex - 1)...min(RatingValue.allCases.count - 1, currentIndex + 1)
                let randomIndex = Int.random(in: possibleRange)
                let rating = RatingValue.allCases[randomIndex]
                
                // Ensure we never use Met/Not Met in regular inspection ratings
                if rating == .met || rating == .notmet {
                    return Rating(category: category.rawValue, rating: mainRating.rawValue)
                }
                return Rating(category: category.rawValue, rating: rating.rawValue)
            }
        }
    }
    
    private func generateThemes(isCompliance: Bool) -> [Theme] {
        let themeList = isCompliance ? complianceThemes : educationThemes
        let numThemes = Int.random(in: 4...6)
        var selectedThemes = Set<String>()
        
        while selectedThemes.count < numThemes {
            selectedThemes.insert(randomItem(themeList))
        }
        
        return selectedThemes.enumerated().map { index, topic in
            Theme(
                frequency: max(10 - index + Int.random(in: -1...1), 1),
                topic: topic
            )
        }
    }
    
    private func formatDate(from timestamp: Timestamp) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMMM yyyy" 
        formatter.locale = Locale(identifier: "en_GB")
        return formatter.string(from: timestamp.date)
    }
    
    // MARK: - Public Generator Function
}
