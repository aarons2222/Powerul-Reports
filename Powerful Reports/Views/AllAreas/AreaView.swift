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


        VStack(spacing: 0){
            CustomHeaderVIew(title: area.name)
        ScrollView {
            
            Color.clear.frame(height: 20)
            
            VStack(spacing: 20) {
                
           
                
                // Grades Card
                CustomCardView("Outcomes") {
                    
                    
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
                CustomCardView("Provider Types") {
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
                CustomCardView("Most Common Themes") {
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
                
                
                CustomCardView("Inspectors") {
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
        .scrollIndicators(.hidden)
        
    }
        .navigationBarHidden(true)
        .ignoresSafeArea()
       
    }
}


