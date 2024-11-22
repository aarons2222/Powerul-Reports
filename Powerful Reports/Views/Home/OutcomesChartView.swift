//
//  InspectionOutcomesChartView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 19/11/2024.
//
import SwiftUI
import Charts

struct OutcomesChartView: View {
    let reports: [Report]
    
    var outcomeData: [OutcomeData] {
        // Process each report to exactly one outcome
        let processedReports = reports.map { report -> (String, Color) in
            // Check for Met/Not Met outcome first
            if !report.outcome.isEmpty {
                return (report.outcome, report.outcome == "Met" ? .yellow : .red)
            }
            // If no Met/Not Met, then it must have an Overall Effectiveness rating
            else if let overallRating = report.ratings.first(where: { $0.category == RatingCategory.overallEffectiveness.rawValue }) {
                if let ratingValue = RatingValue(rawValue: overallRating.rating) {
                    return (overallRating.rating, ratingValue.color)
                }
            }
            
            // This should never happen as each report must have one or the other
            return ("Unknown", .gray)
        }
        
        // Count frequencies and sort
        let outcomeCounts = Dictionary(grouping: processedReports) { $0.0 }
        return outcomeCounts.map { outcome, reports in
            OutcomeData(
                outcome: outcome,
                count: reports.count,
                color: reports.first?.1 ?? .gray
            )
        }.sorted { $0.count > $1.count }
    }
    
    var totalReports: Int {
        reports.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
//                Image(systemName: "chart.pie.fill")
//                    .font(.F)
//                    .foregroundColor(.blue)
                Text("Inspection Outcomes")
                    .font(.headline)
                Spacer()
            }
            
            Chart(outcomeData) { data in
                SectorMark(
                    angle: .value("Count", data.count)
                )
                .foregroundStyle(data.color)
            }
            .frame(height: 160)
            
            // Legend with percentages
            VStack(alignment: .leading, spacing: 4) {
                ForEach(outcomeData) { data in
                    HStack {
                        Circle()
                            .fill(data.color)
                            .frame(width: 8, height: 8)
                        Text(data.outcome)
                            .font(.caption)
                        Spacer()
                        Text("\(calculatePercentage(data.count))%")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    private func calculatePercentage(_ count: Int) -> Int {
        guard totalReports > 0 else { return 0 }
        return Int(round(Double(count) / Double(totalReports) * 100))
    }
}
