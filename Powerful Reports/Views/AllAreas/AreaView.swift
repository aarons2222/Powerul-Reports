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
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Overview Card
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
                        ForEach(area.themes.prefix(10), id: \.topic) { theme in
                            HStack {
                                Text(theme.topic)
                                Spacer()
                                Text("\(theme.frequency)")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                // Inspectors Card
                CardView("Inspectors") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(area.inspectors.keys.sorted()), id: \.self) { inspector in
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
            .padding()
        }
   
        .toolbar {
            ToolbarTitleView(
                icon: "map",
                title: area.name,
                iconColor: .blue
            )
        }
    }
}
