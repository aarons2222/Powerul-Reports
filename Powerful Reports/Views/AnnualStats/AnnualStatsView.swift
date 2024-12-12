import SwiftUI
import Charts

struct AnnualStatsView: View {
    @StateObject private var statsViewModel = AnnualStatsViewModel()
    @ObservedObject var viewModel: InspectionReportsViewModel
    @State private var selectedMonth: (month: String, count: Int, displayMonth: String)?
    @State private var touchLocation: CGPoint = .zero
    @State private var animationProgress: [String: Double] = [:]
    
    private let haptic = UIImpactFeedbackGenerator(style: .light)
    
    // Cache computed properties
    private var maxCount: Int {
        statsViewModel.monthlyStats.map(\.count).max() ?? 0
    }
    
    private var yAxisSteps: [Int] {
        let max = maxCount
        if max == 0 { return [] }
        let step = max <= 5 ? 1 : max / 5
        return stride(from: 0, through: max, by: step).map { $0 }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CustomHeaderVIew(title: "Annual Statistics")
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    Color.clear
                        .frame(height: 20)
                    
               
                    CustomCardView("Monthly Inspection Count") {
                        if statsViewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            chartSection
                                .padding()
                        }
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
                                
                                Text("• Providers receiving 'Good' or 'Outstanding' grade or a 'Met' outcome")
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
                            if inspectorPerformance.isEmpty {
                                Text("No Outstanding grades recorded")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ForEach(Array(inspectorPerformance), id: \.inspector) { item in
                                    HStack {
                                        Text(item.inspector)
                                            .font(.subheadline)
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                        
                                        Spacer()
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            HStack(spacing: 4) {
                                                Text("\(item.outstandingCount)")
                                                    .font(.headline)
                                                    .foregroundColor(.color2)
                                            }
                                            
                                            Text("\(Int((Double(item.outstandingCount) / Double(item.totalInspections)) * 100))% of \(item.totalInspections) reports")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    if item.inspector != inspectorPerformance.last?.inspector {
                                        Divider()
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                    
                    Color.clear
                        .frame(height: 20)
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .onAppear {
            statsViewModel.loadData(from: viewModel.reports)
            animateChartBars()
        }
        .onChange(of: viewModel.reports) { 
            statsViewModel.loadData(from: viewModel.reports)
            animateChartBars()
        }
    }
    
    private func animateChartBars() {
        // Reset animation progress
        let stats = statsViewModel.monthlyStats
        animationProgress = Dictionary(uniqueKeysWithValues: stats.map { ($0.month, 0.0) })
        
        // Animate each bar with a single animation
        withAnimation(.easeInOut(duration: 1.0)) {
            stats.forEach { item in
                animationProgress[item.month] = 1
            }
        }
    }
    
    @ViewBuilder
    private var chartSection: some View {
        VStack(alignment: .leading) {
            Chart {
                ForEach(statsViewModel.monthlyStats, id: \.month) { item in
                    BarMark(
                        x: .value("Count", (animationProgress[item.month] ?? 0) * Double(item.count)),
                        y: .value("Month", item.month)
                    )
                    .foregroundStyle(Color.color2.gradient)
                    .opacity(selectedMonth == nil || selectedMonth?.month == item.month ? 1.0 : 0.3)
                    .cornerRadius(4)
                }
            }
            .chartXAxis {
                AxisMarks(values: yAxisSteps) { value in
                    AxisValueLabel {
                        if let count = value.as(Int.self) {
                            Text("\(count)")
                                .font(.caption)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(preset: .aligned, position: .leading) { value in
                    AxisValueLabel {
                        if let month = value.as(String.self) {
                            Text(month)
                                .font(.caption)
                        }
                    }
                }
            }
            .chartXScale(domain: 0...maxCount)
            .frame(height: 500)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, -16)
            .chartPlotStyle { plotArea in
                plotArea
                    .frame(height: 500)
                    .background(.clear)
            }
            .chartYScale(range: .plotDimension(padding: 0.3))
            .overlay {
                chartOverlay
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedMonth?.month)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: touchLocation)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    handleDragChange(value, in: geometry)
                                }
                                .onEnded { _ in
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        selectedMonth = nil
                                    }
                                }
                        )
                }
            }
        }
    }
    
    @ViewBuilder
    private var chartOverlay: some View {
        if let selected = selectedMonth {
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    Text("\(selected.month): ")
                    Text("\(selected.count)")
                }
                .foregroundStyle(.white)
                .font(.body)
                .fontWeight(.regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.color1)
                )
                .position(x: geometry.size.width - 60, y: max(30, touchLocation.y - 40))
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.8)
                            .combined(with: .opacity)
                            .combined(with: .offset(x: 20)),
                        removal: .scale(scale: 0.8)
                            .combined(with: .opacity)
                            .combined(with: .offset(x: 20))
                    )
                )
            }
        }
    }
    
    private func handleDragChange(_ value: DragGesture.Value, in geometry: GeometryProxy) {
        let currentY = value.location.y
        touchLocation = value.location
        let chartHeight = geometry.size.height
        
        guard currentY >= 0, currentY <= chartHeight else { return }
        
        let yPosition = currentY / chartHeight * CGFloat(statsViewModel.monthlyStats.count - 1)
        let index = Int(round(yPosition))
        
        guard index >= 0 && index < statsViewModel.monthlyStats.count else { return }
        
        let monthData = statsViewModel.monthlyStats[index]
        if selectedMonth?.month != monthData.month {
            haptic.impactOccurred(intensity: 0.3)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedMonth = (month: monthData.month, count: monthData.count, displayMonth: monthData.month)
            }
        }
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
                successRate: p * 100, 
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
    
    private var inspectorPerformance: [(inspector: String, totalInspections: Int, outstandingCount: Int)] {
        let inspectorGroups = Dictionary(grouping: viewModel.reports) { $0.inspector }
        
        let performance = inspectorGroups.map { inspector, reports in
            let outstandingCount = countOutstandingGrades(in: reports)
            return (
                inspector: inspector,
                totalInspections: reports.count,
                outstandingCount: outstandingCount
            )
        }
        
        return Array(performance
            .filter { $0.outstandingCount > 0 && $0.totalInspections >= minInspectionsRequired }
            .sorted { $0.outstandingCount > $1.outstandingCount } // Sort by total Outstanding count
            .prefix(5)) // Show top 5 inspectors
    }
    
    private let minInspectionsRequired = 5 // Minimum inspections required for inclusion
    
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
            return overallRating.rating == "Outstanding"
        }
        
        return false
    }
    
    private func countOutstandingGrades(in reports: [Report]) -> Int {
        reports.filter { report in
            if let overallRating = report.ratings.first(where: { $0.category == "Overall effectiveness" }) {
                return overallRating.rating == "Outstanding"
            }
            return false
        }.count
    }
}
