//
//  AreaProfileView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 19/11/2024.
//

import SwiftUI
import Charts

struct AreaView: View {
    let area: AreaProfile
    let reports: [Report]
    
    @State private var animationPercent = 0.0

    var gradePercentages: [(grade: String, count: Int, percent: Int)] {
          let totalCount = area.grades.values.reduce(0, +)
          guard totalCount > 0 else { return [] }
          
          return area.grades.sorted(by: { $0.key < $1.key }).map { grade, count in
              let percentage = (Double(count) / Double(totalCount)) * 100
              return (grade: grade, count: count, percent: Int(round(percentage)))
          }
      }
      
    
    func getColor(for grade: String) -> Color {
           if let ratingValue = RatingValue(rawValue: grade) {
               return ratingValue.color
           }
           return .gray
       }
    
    
    
    
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
    
    @Binding var path: [NavigationPath]
    
    init(area: AreaProfile, reports: [Report], path: Binding<[NavigationPath]>){
        self.area = area
        self.reports = reports
        self._path = path
        print("Logger: AreaView")
    }
    
    

 
    var body: some View {
        let statistics = ThemeAnalyzer.getThemeStatistics(from: reports, for: area.name)


        VStack{
            CustomHeaderVIew(title: area.name)
        ScrollView {
            
            VStack(spacing: 20) {
                
           
                
                // Grades Card
                CardView("Outcomes") {
                    
                    
                    Chart(gradePercentages,  id: \.grade) { item in
                        SectorMark(
                            angle: .value("Count", Double(item.count) * animationPercent),
                            innerRadius: 70,
                            angularInset: 1
                        )
                        .cornerRadius(5)
                        .foregroundStyle(getColor(for: item.grade))
                    }
                    .frame(height: 250)
                    .onAppear {
                        withAnimation(.linear(duration: 0.6)) {
                                    animationPercent = 1.0
                                }
                            }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(gradePercentages, id: \.grade) { item in
                       
                            HStack {
                                
                                Image(systemName: "largecircle.fill.circle")
                                    .font(.body)
                                    .foregroundStyle(getColor(for: item.grade))
                                Text(item.grade)
                                    .foregroundColor(.color4)
                                Spacer()
                                Text("\(item.percent)%")
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
                        
                        ForEach(Array(area.inspectors.sorted(by: { $0.key < $1.key })), id: \.key) { inspector, count in
                            Button {
                                path.append(.inspectorProfile(inspector))
                            } label: {
                                HStack {
                                    Text(inspector)
                                    Spacer()
                                    Text("\(count)")
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

