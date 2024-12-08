import SwiftUI
import Charts

struct AnnualStatsView: View {
    @ObservedObject var viewModel: InspectionReportsViewModel
    
    @State private var selectedMonth: (month: String, count: Int, displayMonth: String)?
    @State private var selectedX: CGFloat?
    
    private let minInspectionsRequired = 5 // Minimum inspections required for inclusion
    
    private struct MonthKey: Hashable {
        let sortKey: String
        let displayKey: String
    }
    
    private struct MonthlyInspectionCount {
        let month: String
        let count: Int
        let date: Date
    }
    
    private var monthlyInspectionCounts: [MonthlyInspectionCount] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM"
        
        let counts = Dictionary(grouping: viewModel.reports) { report in
            if let dateStr = report.date.components(separatedBy: " - ").last?.trimmingCharacters(in: .whitespaces),
               let date = dateFormatter.date(from: dateStr) {
                let components = Calendar.current.dateComponents([.year, .month], from: date)
                return String(format: "%04d-%02d", components.year!, components.month!)
            }
            return "Unknown"
        }
        .filter { $0.key != "Unknown" }
        .map { key, reports in
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "yyyy-MM"
            let date = monthFormatter.date(from: key) ?? Date()
            let month = displayFormatter.string(from: date)
            return MonthlyInspectionCount(month: month, count: reports.count, date: date)
        }
        .sorted { $0.date < $1.date }
        .suffix(12)  // Only show last 12 months
        
        return Array(counts)
    }
    
    private func isSuccessful(_ report: Report) -> Bool {
        // For childminder inspections, check if "Met" is the outcome
        if report.typeOfProvision.contains("Childminder") {
            return report.outcome == "Met"
        }
        
        // For other inspections, check for "Good" or "Outstanding" in overall effectiveness
        if let overallRating = report.ratings.first(where: { $0.category == "Overall effectiveness" }) {
            return overallRating.rating == "Good" || overallRating.rating == "Outstanding"
        }
        
        return false
    }
    
    private func hasOutstandingGrade(_ report: Report) -> Bool {
        // For childminder inspections, they can't get Outstanding
        if report.typeOfProvision.contains("Childminder") {
            return false
        }
        
        // Check for Outstanding in overall effectiveness
        if let overallRating = report.ratings.first(where: { $0.category == "Overall effectiveness" }) {
            return overallRating.rating == "Outstanding" || overallRating.rating == "1"
        }
        
        return false
    }
    
    private var inspectorPerformance: [(inspector: String, totalInspections: Int, outstandingCount: Int)] {
        let inspectorGroups = Dictionary(grouping: viewModel.reports) { $0.inspector }
        
        return inspectorGroups.compactMap { inspector, reports in
            guard !reports.isEmpty else { return nil }
            
            let outstandingInspections = reports.filter(hasOutstandingGrade).count
            
            return (
                inspector: inspector,
                totalInspections: reports.count,
                outstandingCount: outstandingInspections
            )
        }
        .sorted { $0.outstandingCount > $1.outstandingCount } // Sort by number of Outstanding grades
        .prefix(5) // Show top 5 inspectors
        .filter { $0.outstandingCount > 0 } // Only show inspectors who have Outstanding grades
    }
    
    private var localAuthorityPerformance: [(authority: String, successRate: Double, totalInspections: Int)] {
        let authorityGroups = Dictionary(grouping: viewModel.reports) { $0.localAuthority }
        
        return authorityGroups.compactMap { authority, reports in
            guard !reports.isEmpty && reports.count >= minInspectionsRequired else { return nil }
            
            let successfulInspections = reports.filter(isSuccessful).count
            let successRate = Double(successfulInspections) / Double(reports.count)
            
            // Wilson score lower bound calculation
            let n = Double(reports.count)
            let p = successRate
            let z = 1.96 // 95% confidence level
            
            let left = p + (z * z) / (2 * n)
            let right = z * sqrt((p * (1 - p) + (z * z) / (4 * n)) / n)
            let under = 1 + (z * z) / n
            
            let score = ((left - right) / under) * 100
            
            return (
                authority: authority,
                successRate: p * 100, // Original success rate for display
                totalInspections: reports.count
            )
        }
        .sorted { a, b in
            // Primary sort by total successful inspections
            let aSuccessful = Double(a.totalInspections) * (a.successRate / 100)
            let bSuccessful = Double(b.totalInspections) * (b.successRate / 100)
            
            if abs(aSuccessful - bSuccessful) > 1 {
                return aSuccessful > bSuccessful
            }
            
            // Secondary sort by success rate if total successful inspections are close
            return a.successRate > b.successRate
        }
    }
    
    var body: some View {
        VStack {
            CustomHeaderVIew(title: "Annual Statistics")
            
            ScrollView {
                VStack(spacing: 20) {
                    // Monthly Inspection Count
                    CustomCardView("Monthly Inspection Count") {
                        VStack(alignment: .leading, spacing: 16) {
                            // Chart
                            Chart {
                                ForEach(monthlyInspectionCounts, id: \.month) { item in
                                    BarMark(
                                        x: .value("Month", item.month),
                                        y: .value("Count", item.count)
                                    )
                                    .foregroundStyle(Color.color2.gradient)
                                    .cornerRadius(4)
                                }
                            }
                            .chartXAxis {
                                AxisMarks(values: .automatic) { value in
                                    AxisValueLabel {
                                        if let month = value.as(String.self) {
                                            Text(month)
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading) { value in
                                    AxisValueLabel {
                                        if let count = value.as(Int.self) {
                                            Text("\(count)")
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                            .frame(height: 200)
                            
                        
                        }
                        .padding()
                    }
                    
                    // Top Performing Local Authorities
                    CustomCardView("Top Performing Local Authorities") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(localAuthorityPerformance.prefix(5), id: \.authority) { item in
                                HStack {
                                    Text(item.authority)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("\(Int(round(item.successRate)))%")
                                            .font(.headline)
                                            .foregroundColor(.color2)
                                        
                                        Text("of \(item.totalInspections) reports")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                if item.authority != localAuthorityPerformance.prefix(5).last?.authority {
                                    Divider()
                                }
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            // Key explanation
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Success Rate Criteria:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fontWeight(.medium)
                                
                                Text("• Childminders: 'Met' outcomes")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("• Other providers: 'Good' or 'Outstanding' grades")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("• Minimum \(minInspectionsRequired) inspections required")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("• Ranking considers both success rate and number of reports")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 4)
                        }
                        .padding()
                    }
                    
                    // Inspector Performance
                    CustomCardView("Most Outstanding Grades Given") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(inspectorPerformance, id: \.inspector) { item in
                                HStack {
                                    Text(item.inspector)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("\(item.outstandingCount)")
                                            .font(.headline)
                                            .foregroundColor(.color2)
                                        
                                        Text("of \(item.totalInspections) reports")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                if item.inspector != inspectorPerformance.last?.inspector {
                                    Divider()
                                }
                            }
                            
                            if inspectorPerformance.isEmpty {
                                Text("No Outstanding grades recorded")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            }
                        }
                        .padding()
                    }
                }
                .padding(.horizontal)
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}
