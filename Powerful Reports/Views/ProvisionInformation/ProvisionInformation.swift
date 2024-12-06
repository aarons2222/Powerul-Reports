//
//  ProvisionInformation.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 28/11/2024.
//

import SwiftUI
import Charts


// ProvisionInformation components
struct ProvisionDistributionChart: View {
    let providerData: [(type: String, outcomes: [String: Int], total: Int)]
    
    var body: some View {
        Chart {
            ForEach(providerData, id: \.type) { provider in
                ForEach(Array(provider.outcomes), id: \.key) { outcome, count in
                    BarMark(
                        x: .value("Count", count),
                        y: .value("Provider", provider.type)
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
        .frame(height: min(CGFloat(providerData.count * 60), 400))
    }
}

struct SuccessRateView: View {
    let successRates: [(type: String, rate: Double)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(successRates, id: \.type) { data in
                VStack(alignment: .leading, spacing: 4) {
                    Text(data.type)
                        .font(.subheadline)
                        .foregroundColor(.color4)
                    
                    HStack {
                        Rectangle()
                            .fill(data.rate >= 80 ? Color.color1 : 
                                  data.rate >= 60 ? Color.color5 :
                                  Color.color6)
                            .frame(width: max(CGFloat(data.rate), 0) * 2, height: 20)
                            .cornerRadius(4)
                        
                        Text(String(format: "%.1f%%", data.rate))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

struct OutcomeRow: View {
    let outcome: String
    let count: Int
    let total: Int
    
    var body: some View {
        
        HStack {
            Image(systemName: "largecircle.fill.circle")
                .font(.body)
                .foregroundStyle(outcomeColor(outcome))
        
            Text(outcome)
                .font(.body)
                .foregroundColor(.color4)


            
                Spacer()
        
            Text("\(count)")
                    .font(.body)
                    .foregroundColor(.gray)

            Text("(\(String(format: "%.1f%%", Double(count) / Double(total) * 100)))")
                .font(.footnote)
                .foregroundColor(.gray)
        }
    }
    
    private func outcomeColor(_ outcome: String) -> Color {
        switch outcome {
        case "Outstanding": return .color7
        case "Good": return .color1
        case "Requires improvement": return .color5
        case "Inadequate": return .color8
        case "Met": return .color2
        case "Not Met": return .color6
        default: return .gray
        }
    }
}

struct ProviderSection: View {
    let type: String
    let outcomes: [String: Int]
    let total: Int
    let isLast: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(type)
                .font(.headline)
                .foregroundColor(.color4)
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(outcomes.sorted { $0.value > $1.value }), id: \.key) { outcome, count in
                    OutcomeRow(outcome: outcome, count: count, total: total)
                }
            }
    
            
            if !isLast {
                Divider()
                    .padding(.vertical, 8)
            }
        }
    }
}

struct DetailedAnalysisView: View {
    let providerData: [(type: String, outcomes: [String: Int], total: Int)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(Array(providerData.enumerated()), id: \.element.type) { index, provider in
                ProviderSection(
                    type: provider.type,
                    outcomes: provider.outcomes,
                    total: provider.total,
                    isLast: index == providerData.count - 1
                )
            }
        }
    }
}

struct ProvisionInformation: View {
    let reports: [Report]
    @State private var selectedProvisionType: String?
    
    private var providerData: [(type: String, outcomes: [String: Int], total: Int)] {
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
            return (type, outcomeCounts, typeReports.count)
        }.sorted { $0.total > $1.total }
    }
    
    private var successRates: [(type: String, rate: Double)] {
        providerData.map { data in
            let successCount = data.outcomes.filter { key, _ in
                ["Outstanding", "Good", "Met"].contains(key)
            }.values.reduce(0, +)
            let rate = Double(successCount) / Double(data.total) * 100
            return (data.type, rate)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CustomHeaderVIew(title: "Provider Analysis")
            
            if reports.isEmpty {
                Text("No data available")
                    .foregroundColor(.gray)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        CardView("Overall Distribution") {
                            ProvisionDistributionChart(providerData: providerData)
                        }
                        
                        CardView("Success Rates") {
                            SuccessRateView(successRates: successRates)
                        }
                        
                        CardView("Detailed Analysis") {
                            DetailedAnalysisView(providerData: providerData)
                        }
                    }
                    .padding()
                }
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}
