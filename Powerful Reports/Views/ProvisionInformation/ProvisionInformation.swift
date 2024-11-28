//
//  ProvisionTypes.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 28/11/2024.
//

import SwiftUI
import Charts


struct ProvisionInformation: View {
    let reports: [Report]
    
    private var providerData: [(type: String, outcomes: [String: Int])] {
        guard !reports.isEmpty else { return [] }
        
        let groupedReports = Dictionary(grouping: reports) { report in
            report.typeOfProvision.isEmpty ? "Unknown" : report.typeOfProvision
        }
        
        return groupedReports.map { type, typeReports in
            let outcomes = typeReports.map { report in
                if !report.outcome.isEmpty {
                    return report.outcome
                } else if let rating = report.ratings.first(where: { $0.category == "Overall effectiveness" })?.rating {
                    return rating
                }
                return "Unknown"
            }
            let outcomeCounts = Dictionary(grouping: outcomes) { $0 }.mapValues { $0.count }
            return (type, outcomeCounts)
        }.sorted { $0.type < $1.type }
    }
    
    var body: some View {
        VStack {
            CustomHeaderVIew(title: "Provider Outcomes")
            if reports.isEmpty {
                Text("No data available")
                    .foregroundColor(.gray)
            } else {
                ScrollView {
                    VStack {
                        Chart {
                            ForEach(providerData, id: \.type) { provider in
                                ForEach(Array(provider.outcomes), id: \.key) { outcome, count in
                                    BarMark(
                                        x: .value("Provider", provider.type),
                                        y: .value("Count", count)
                                    )
                                    .foregroundStyle(by: .value("Outcome", outcome))
                                }
                            }
                        }
                        .chartForegroundStyleScale([
                            "Outstanding": .color7,
                            "Good": .color1,
                            "Requires improvement": .color5,
                            "Inadequate": .color8,
                            "Met": .color2,
                            "Not Met": .color6,
                            "Unknown": .gray
                        ])
                        .chartLegend(.hidden)
                        .frame(height: 600)
                    }
                    .padding()
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}
