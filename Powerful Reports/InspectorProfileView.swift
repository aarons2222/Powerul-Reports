//
//  InspectorProfileView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 19/11/2024.
//

import SwiftUI
import Charts

struct InspectorProfileView: View {
    let profile: InspectorProfile
    let reports: [Report]  // Add reports parameter
    
    private var recentReports: [Report] {
       Array(reports
           .filter { $0.inspector == profile.name }
           .sorted { report1, report2 in
               let dateFormatter = DateFormatter()
               dateFormatter.dateFormat = "dd/MM/yyyy"
               
               let date1 = dateFormatter.date(from: report1.date) ?? Date.distantPast
               let date2 = dateFormatter.date(from: report2.date) ?? Date.distantPast
               
               return date1 > date2
           }
           .prefix(10))
    }
    
    var body: some View {
        List {
            Section(header: Text("Overview")) {
                LabeledContent("Total Inspections", value: "\(profile.totalInspections)")
            }
            
            Section(header: Text("Recent Inspections")) {
                ForEach(recentReports) { report in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(report.referenceNumber)
                            .font(.headline)
                        Text(report.date)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Text(report.typeOfProvision)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Section(header: Text("Areas Covered")) {
                ForEach(Array(profile.areas.keys.sorted()), id: \.self) { area in
                    LabeledContent(area, value: "\(profile.areas[area] ?? 0)")
                }
            }
            
        
            Section(header: Text("Grades")) {
                let gradeColors: [String: Color] = [
                    "Outstanding": .green,
                    "Good": .blue,
                    "Requires Improvement": .orange,
                    "Inadequate": .red
                ]
                
                Chart {
                    ForEach(Array(profile.grades.keys.sorted()), id: \.self) { grade in
                        SectorMark(
                            angle: .value("Count", profile.grades[grade] ?? 0)
                        )
                        .foregroundStyle(gradeColors[grade, default: .gray])
                        
                    }
                }
                .frame(height: 200)
                .padding()
                
                ForEach(Array(profile.grades.keys.sorted()), id: \.self) { grade in
                    LabeledContent(grade, value: "\(profile.grades[grade] ?? 0)")
                }
            }
            
        }
        .navigationTitle(profile.name)
    }
}


