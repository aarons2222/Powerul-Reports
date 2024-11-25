//
//  AreaProfileView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 19/11/2024.
//

import SwiftUI

struct AreaView: View {
    let area: AreaProfile
    let reports: [Report]
    
    private func getInspectorProfile(name: String) -> InspectorProfile {
       print("Getting profile for inspector: \(name)")
       let inspectorReports = reports.filter { $0.inspector == name }
       print("Found \(inspectorReports.count) reports")
       
       let areas = Dictionary(grouping: inspectorReports) { $0.localAuthority }
           .mapValues { $0.count }
       print("Areas covered: \(areas)")
       
       var allGrades: [String: Int] = [:]
       
       inspectorReports.forEach { report in
           if let overallRating = report.ratings.first(where: { $0.category == RatingCategory.overallEffectiveness.rawValue }) {
               print("Adding overall rating: \(overallRating.rating)")
               allGrades[overallRating.rating, default: 0] += 1
           } else if !report.outcome.isEmpty {
               print("Adding outcome: \(report.outcome)")
               allGrades[report.outcome, default: 0] += 1
           }
       }
       print("Final grades: \(allGrades)")
       
       return InspectorProfile(
           name: name,
           totalInspections: inspectorReports.count,
           areas: areas,
           grades: allGrades
       )
    }
    
    init(area: AreaProfile, reports: [Report]){
        self.area = area
        self.reports = reports
        print("Logger: AreaView")
    }
    
    var body: some View {
        let statistics = ThemeAnalyzer.getThemeStatistics(from: reports, for: area.name)


        VStack{
            CustomHeaderVIew(title: area.name)
        ScrollView {
            
            VStack(spacing: 20) {
                
                CardView("Overview") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Inspections: \(area.totalInspections)")
                            .font(.headline)
                    }
                }
                
                // Grades Card
                CardView("Outcomes") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(area.grades.keys.sorted()), id: \.self) { grade in
                            HStack {
                                Text(grade)
                                Spacer()
                                Text("\(area.grades[grade, default: 0])")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                // Provision Types Card
                CardView("Provider Types") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(area.provisionTypes.keys.sorted()), id: \.self) { type in
                            HStack {
                                Text(type)
                                Spacer()
                                Text("\(area.provisionTypes[type, default: 0])")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                // Top Themes Card
                CardView("Most Common Themes") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(statistics.topThemes.prefix(10)) { theme in
                            HStack {
                                Text(theme.topic)
                                Spacer()
                                Text("\(theme.count)")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                
                CardView("Inspectors") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(area.inspectors.keys.sorted()), id: \.self) { inspector in
                            NavigationLink(destination: InspectorProfileView(profile: getInspectorProfile(name: inspector), reports: reports)) {
                                HStack {
                                    Text(inspector)
                                    Spacer()
                                    Text("\(area.inspectors[inspector, default: 0])")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
        
    }
        .navigationBarHidden(true)
        .ignoresSafeArea()
       
    }
}


struct ThemeFrequency: Identifiable {
    let id = UUID()
    let topic: String
    let count: Int
}
class ThemeAnalyzer {
    // Original methods for Local Authority
    static func analyzeThemes(from reports: [Report], for localAuthority: String) -> [ThemeFrequency] {
        var themeCounts: [String: Int] = [:]
        
        let areaReports = reports.filter { $0.localAuthority == localAuthority }
        
        for report in areaReports {
            for theme in report.themes {
                themeCounts[theme.topic, default: 0] += 1
            }
        }
        
        let sortedThemes = themeCounts.map { topic, count in
            ThemeFrequency(topic: topic, count: count)
        }.sorted { $0.count > $1.count }
        
        return sortedThemes
    }
    
    static func getThemeStatistics(from reports: [Report], for areaId: String) -> (total: Int, topThemes: [ThemeFrequency], percentages: [String: Double]) {
        let themeFrequencies = analyzeThemes(from: reports, for: areaId)
        let totalThemeOccurrences = themeFrequencies.reduce(0) { $0 + $1.count }
        
        var percentages: [String: Double] = [:]
        themeFrequencies.forEach { theme in
            percentages[theme.topic] = Double(theme.count) / Double(totalThemeOccurrences) * 100
        }
        
        return (
            total: totalThemeOccurrences,
            topThemes: themeFrequencies,
            percentages: percentages
        )
    }
    
    // New methods for Inspector
    static func analyzeThemesByInspector(from reports: [Report], for inspector: String) -> [ThemeFrequency] {
        var themeCounts: [String: Int] = [:]
        
        let inspectorReports = reports.filter { $0.inspector == inspector }
        
        for report in inspectorReports {
            for theme in report.themes {
                themeCounts[theme.topic, default: 0] += 1
            }
        }
        
        let sortedThemes = themeCounts.map { topic, count in
            ThemeFrequency(topic: topic, count: count)
        }.sorted { $0.count > $1.count }
        
        return sortedThemes
    }
    
    static func getInspectorThemeStatistics(from reports: [Report], for inspector: String) -> (total: Int, topThemes: [ThemeFrequency], percentages: [String: Double]) {
        let themeFrequencies = analyzeThemesByInspector(from: reports, for: inspector)
        let totalThemeOccurrences = themeFrequencies.reduce(0) { $0 + $1.count }
        
        var percentages: [String: Double] = [:]
        themeFrequencies.forEach { theme in
            percentages[theme.topic] = Double(theme.count) / Double(totalThemeOccurrences) * 100
        }
        
        return (
            total: totalThemeOccurrences,
            topThemes: themeFrequencies,
            percentages: percentages
        )
    }
}

