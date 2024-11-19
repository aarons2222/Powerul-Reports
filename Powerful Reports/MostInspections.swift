//
//  MostInspections.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 19/11/2024.
//

import SwiftUI

struct InspectorProfile: Identifiable {
    let id = UUID()
    let name: String
    let totalInspections: Int
    let areas: [String: Int]
    let grades: [String: Int]
}

struct MostInspections: View {
    let reports: [Report]
    
    private func getInspectorProfile(name: String) -> InspectorProfile {
        let inspectorReports = reports.filter { $0.inspector == name }
        
        let areas = Dictionary(grouping: inspectorReports) { $0.localAuthority }
            .mapValues { $0.count }
        
        var allGrades: [String: Int] = [:]
        
        // Count overall effectiveness ratings
        inspectorReports.forEach { report in
            if let overallRating = report.ratings.first(where: { $0.category == RatingCategory.overallEffectiveness.rawValue }) {
                allGrades[overallRating.rating, default: 0] += 1
            } else {
                // If no overall effectiveness, use outcome (met/not met)
                if !report.outcome.isEmpty {
                    allGrades[report.outcome, default: 0] += 1
                }
            }
        }
        
        return InspectorProfile(
            name: name,
            totalInspections: inspectorReports.count,
            areas: areas,
            grades: allGrades
        )
    }
    
    private var groupedInspectorData: [String: [InstpectorData]] {
        let inspectorCounts = Dictionary(grouping: reports) { $0.inspector }
            .mapValues { $0.count }
            .filter { !$0.key.isEmpty }
        
        let inspectorData = inspectorCounts.sorted { $0.value > $1.value }
            .map { InstpectorData(name: $0.key, count: $0.value) }
        
        return Dictionary(grouping: inspectorData) {
            String($0.name.prefix(1)).uppercased()
        }
    }
    
    var body: some View {
        
            VStack(alignment: .leading, spacing: 8) {
                List {
                    ForEach(Array(groupedInspectorData.keys.sorted()), id: \.self) { letter in
                        Section(header: Text(letter)) {
                            ForEach(groupedInspectorData[letter] ?? []) { item in
                                NavigationLink(destination: InspectorProfileView(profile: getInspectorProfile(name: item.name), reports: reports)) {
                                    HStack(alignment: .center) {
                                        Text(item.name)
                                            .font(.system(.body, design: .rounded))
                                        
                                        Spacer()
                                        
                                        Text("\(item.count)")
                                            .font(.system(.body, design: .rounded))
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 4)
                                    }
                                }
                            }
                        }
                    }
                }
            }
 
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack {
                        Image(systemName: "person.crop.badge.magnifyingglass")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("Most Inspections")
                            .font(.title3)
                        Spacer()
                    }
                }
            }
        }
    }






