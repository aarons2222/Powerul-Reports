import SwiftUI
import Charts

struct AnnualStatsView: View {
    @ObservedObject var viewModel: InspectionReportsViewModel

    
    private var monthlyInspectionCounts: [(month: String, count: Int)] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        
        let groupedByMonth = Dictionary(grouping: viewModel.reports) { report in
            let date = dateFormatter.date(from: String(report.date.prefix(7))) ?? Date()
            return dateFormatter.string(from: date)
        }
        
        return groupedByMonth
            .map { (month: $0.key, count: $0.value.count) }
            .sorted { $0.month > $1.month }
    }
    
    private var inspectorPerformance: [(inspector: String, avgRating: Double, inspectionCount: Int)] {
        let inspectorGroups = Dictionary(grouping: viewModel.reports) { $0.inspector }
        
        return inspectorGroups.map { inspector, reports in
            let successfulInspections = reports.filter { report in
                ["Outstanding", "Good", "Met"].contains(report.outcome)
            }.count
            
            let avgRating = Double(successfulInspections) / Double(reports.count) * 100
            return (inspector: inspector, avgRating: avgRating, inspectionCount: reports.count)
        }
        .sorted { $0.avgRating > $1.avgRating }
    }
    
    private var improvementMetrics: (improved: Int, declined: Int, unchanged: Int) {
        var improved = 0
        var declined = 0
        var unchanged = 0
        
        for report in viewModel.reports {
            guard !report.previousInspection.isEmpty && !report.outcome.isEmpty else { continue }
            
            let currentRating = ratingValue(report.outcome)
            let previousRating = ratingValue(report.previousInspection)
            
            if currentRating > previousRating {
                improved += 1
            } else if currentRating < previousRating {
                declined += 1
            } else {
                unchanged += 1
            }
        }
        
        return (improved, declined, unchanged)
    }
    
    private var localAuthorityPerformance: [(authority: String, successRate: Double)] {
        let authorityGroups = Dictionary(grouping: viewModel.reports) { $0.localAuthority }
        
        return authorityGroups.map { authority, reports in
            let successfulInspections = reports.filter { report in
                ["Outstanding", "Good", "Met"].contains(report.outcome)
            }.count
            
            let successRate = Double(successfulInspections) / Double(reports.count) * 100
            return (authority: authority, successRate: successRate)
        }
        .sorted { $0.successRate > $1.successRate }
    }
    
    private func ratingValue(_ rating: String) -> Int {
        switch rating {
        case "Outstanding": return 4
        case "Good": return 3
        case "Met": return 3
        case "Requires improvement": return 2
        case "Not Met": return 1
        case "Inadequate": return 0
        default: return -1
        }
    }
    
    var body: some View {
        VStack{
            CustomHeaderVIew(title: "Annual Statistics")

        ScrollView {
            VStack(spacing: 20) {
                
                // Monthly Inspection Trend
                CardView("Monthly Inspection Trend") {
                    Chart {
                        ForEach(monthlyInspectionCounts.prefix(12), id: \.month) { item in
                            LineMark(
                                x: .value("Month", item.month),
                                y: .value("Count", item.count)
                            )
                            .foregroundStyle(.color1)
                            
                            PointMark(
                                x: .value("Month", item.month),
                                y: .value("Count", item.count)
                            )
                            .foregroundStyle(.color2)
                        }
                    }
                    .frame(height: 200)
                    .padding()
                }
                
                // Improvement Metrics
                CardView("Year-over-Year Changes") {
                    HStack {
                        MetricView(
                            title: "Improved",
                            value: "\(improvementMetrics.improved)",
                            color: .color1
                        )
                        
                        Divider()
                        
                        MetricView(
                            title: "Unchanged",
                            value: "\(improvementMetrics.unchanged)",
                            color: .color7
                        )
                        
                        Divider()
                        
                        MetricView(
                            title: "Declined",
                            value: "\(improvementMetrics.declined)",
                            color: .color6
                        )
                    }
                    .padding()
                }
                
                // Top Performing Local Authorities
                CardView("Top Performing Local Authorities") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(localAuthorityPerformance.prefix(5), id: \.authority) { item in
                            HStack {
                                Text(item.authority)
                                    .font(.subheadline)
                                    .foregroundColor(.color4)
                                
                                Spacer()
                                
                                Text(String(format: "%.1f%%", item.successRate))
                                    .font(.headline)
                                    .foregroundColor(.color1)
                            }
                            
                            if item.authority != localAuthorityPerformance.prefix(5).last?.authority {
                                Divider()
                            }
                        }
                    }
                    .padding()
                }
                
                // Inspector Performance
                CardView("Inspector Performance") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(inspectorPerformance.prefix(5), id: \.inspector) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.inspector)
                                    .font(.subheadline)
                                    .foregroundColor(.color4)
                                
                                HStack {
                                    // Success rate bar
                                    GeometryReader { geometry in
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color.color1.opacity(0.3))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(Color.color1)
                                                    .frame(width: geometry.size.width * CGFloat(item.avgRating / 100))
                                                , alignment: .leading
                                            )
                                    }
                                    .frame(height: 8)
                                    
                                    Text("\(Int(item.avgRating))%")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Text("(\(item.inspectionCount) inspections)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            if item.inspector != inspectorPerformance.prefix(5).last?.inspector {
                                Divider()
                            }
                        }
                    }
                    .padding()
                }
            }
            
        }
        .padding(.horizontal)
        
    }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}

struct MetricView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}
