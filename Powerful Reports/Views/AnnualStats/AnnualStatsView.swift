import SwiftUI
import Charts

struct AnnualStatsView: View {
    @ObservedObject var viewModel: InspectionReportsViewModel
    
    @State private var selectedMonth: (month: String, count: Int, displayMonth: String)?
    @State private var selectedX: CGFloat?
    
    private struct MonthKey: Hashable {
        let sortKey: String
        let displayKey: String
    }
    
    private var monthlyInspectionCounts: [(month: String, count: Int, displayMonth: String)] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "yyyy-MM"
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM yy"
        
        let groupedByMonth = Dictionary(grouping: viewModel.reports) { report in
            if let dateStr = report.date.components(separatedBy: " - ").last?.trimmingCharacters(in: .whitespaces),
               let date = dateFormatter.date(from: dateStr) {
                return MonthKey(
                    sortKey: monthFormatter.string(from: date),
                    displayKey: displayFormatter.string(from: date)
                )
            }
            return MonthKey(sortKey: "Unknown", displayKey: "Unknown")
        }
        
        return groupedByMonth
            .filter { $0.key.sortKey != "Unknown" }
            .map { (month: $0.key.sortKey, count: $0.value.count, displayMonth: $0.key.displayKey) }
            .sorted { $0.month < $1.month }
            .suffix(12)
    }
    
    private func isSuccessful(_ report: Report) -> Bool {
        // For childminder inspections (using outcome)
        if report.typeOfProvision.contains("Childminder") {
            return report.outcome == "Met"
        }
        
        // For other inspections (using overall effectiveness)
        if let overallRating = report.ratings.first(where: { $0.category == "Overall effectiveness" }) {
            return ["Outstanding", "Good"].contains(overallRating.rating)
        }
        
        return false
    }
    
    private var inspectorPerformance: [(inspector: String, avgRating: Double, inspectionCount: Int)] {
        let inspectorGroups = Dictionary(grouping: viewModel.reports) { $0.inspector }
        
        return inspectorGroups.compactMap { inspector, reports in
            guard !reports.isEmpty else { return nil }
            
            let successfulInspections = reports.filter(isSuccessful).count
            let avgRating = Double(successfulInspections) / Double(reports.count) * 100
            return (inspector: inspector, avgRating: avgRating, inspectionCount: reports.count)
        }
        .sorted { $0.avgRating > $1.avgRating }
    }
    
    private var localAuthorityPerformance: [(authority: String, successRate: Double)] {
        let authorityGroups = Dictionary(grouping: viewModel.reports) { $0.localAuthority }
        
        return authorityGroups.compactMap { authority, reports in
            guard !reports.isEmpty else { return nil }
            
            let successfulInspections = reports.filter(isSuccessful).count
            let successRate = Double(successfulInspections) / Double(reports.count) * 100
            return (authority: authority, successRate: successRate)
        }
        .sorted { $0.successRate > $1.successRate }
    }
    
    var body: some View {
        VStack {
            CustomHeaderVIew(title: "Annual Statistics")
            
            ScrollView {
                VStack(spacing: 20) {
                    // Monthly Inspection Trend
                    CardView("Monthly Inspection Count") {
                        VStack(alignment: .leading, spacing: 8) {
                            ZStack(alignment: .topLeading) {
                                Chart {
                                    ForEach(monthlyInspectionCounts, id: \.month) { item in
                                        LineMark(
                                            x: .value("Month", item.displayMonth),
                                            y: .value("Inspections", item.count)
                                        )
                                        .foregroundStyle(.color1)
                                        .interpolationMethod(.catmullRom)
                                        .symbol {
                                            Circle()
                                                .fill(.color2)
                                                .frame(width: 8, height: 8)
                                        }
                                        .symbolSize(30)
                                        
                                        AreaMark(
                                            x: .value("Month", item.displayMonth),
                                            y: .value("Inspections", item.count)
                                        )
                                        .foregroundStyle(
                                            .linearGradient(
                                                colors: [.color1.opacity(0.3), .clear],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .interpolationMethod(.catmullRom)
                                    }
                                    
                                    if let selected = selectedMonth {
                                        RuleMark(
                                            x: .value("Selected", selected.displayMonth)
                                        )
                                        .foregroundStyle(.color2)
                                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                        
                                        PointMark(
                                            x: .value("Month", selected.displayMonth),
                                            y: .value("Count", selected.count)
                                        )
                                        .foregroundStyle(.color2)
                                        .symbolSize(100)
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks { value in
                                        AxisValueLabel {
                                            if let str = value.as(String.self) {
                                                Text(str)
                                                    .font(.caption)
                                                    .rotationEffect(.degrees(-45))
                                                    .offset(y: 10)
                                            }
                                        }
                                    }
                                }
                                .chartYAxis {
                                    AxisMarks { value in
                                        AxisValueLabel {
                                            if let count = value.as(Int.self) {
                                                Text("\(count)")
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                }
                                .frame(height: 240)
                                .padding(.bottom, 40) // Add extra padding for x-axis labels
                                .chartOverlay { proxy in
                                    GeometryReader { geometry in
                                        Rectangle()
                                            .fill(.clear)
                                            .contentShape(Rectangle())
                                            .gesture(
                                                DragGesture(minimumDistance: 0)
                                                    .onChanged { value in
                                                        let currentX = value.location.x
                                                        guard currentX >= 0,
                                                              currentX <= geometry.size.width,
                                                              let month = proxy.value(atX: currentX, as: String.self) else {
                                                            return
                                                        }
                                                        
                                                        if let item = monthlyInspectionCounts.first(where: { $0.displayMonth == month }) {
                                                            selectedMonth = item
                                                            selectedX = currentX
                                                        }
                                                    }
                                                    .onEnded { _ in
                                                        withAnimation(.easeOut) {
                                                            selectedMonth = nil
                                                            selectedX = nil
                                                        }
                                                    }
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 8)
                            
                            if let selected = selectedMonth {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(selected.displayMonth)
                                            .font(.headline)
                                        Text("\(selected.count) inspections")
                                            .foregroundColor(.color1)
                                            .font(.subheadline)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.color1.opacity(0.1))
                                )
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.bottom, 20)
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
                .padding(.horizontal)
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}
