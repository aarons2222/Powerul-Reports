//
//  AnnualStats.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 25/11/2024.
//
import SwiftUI
import Charts

struct AnnualStats: View {
    let allReports: [Report]
    
    // Process reports into monthly data
    private var monthlyData: [MonthlyData] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy" // Adjust this to match your date string format
        
        // Group reports by month
        let groupedByMonth = Dictionary(grouping: allReports) { report -> Int in
            let date = dateFormatter.date(from: report.date) ?? Date()
            return Calendar.current.component(.month, from: date)
        }
        
        // Process each month's data
        let monthlyProcessedData = groupedByMonth.map { month, reports in
            let monthFormatter = DateFormatter()
            monthFormatter.dateFormat = "MMM"
            let monthDate = Calendar.current.date(from: DateComponents(month: month))!
            let monthName = monthFormatter.string(from: monthDate)
            
            // Process outcomes similar to your existing logic
            let processedReports = reports.map { report -> (String, Color) in
                if !report.outcome.isEmpty {
                    return (report.outcome, report.outcome == "Met" ? .color2 : .color6)
                } else if let overallRating = report.ratings.first(where: { $0.category == RatingCategory.overallEffectiveness.rawValue }),
                          let ratingValue = RatingValue(rawValue: overallRating.rating) {
                    return (overallRating.rating, ratingValue.color)
                }
                return ("Unknown", .gray)
            }
            
            // Group by outcome for this month
            let outcomeCounts = Dictionary(grouping: processedReports) { $0.0 }
            return outcomeCounts.map { outcome, outcomeReports in
                MonthlyData(
                    monthNumber: month,
                    month: monthName,
                    outcome: outcome,
                    count: outcomeReports.count,
                    color: outcomeReports.first?.1 ?? .gray
                )
            }
        }
            .flatMap { $0 } // Flatten the array of arrays
            .sorted { $0.monthNumber < $1.monthNumber } // Sort by month number
        
        return monthlyProcessedData
    }
    
    var body: some View {
        
        VStack{
            CustomHeaderVIew(title: "All Stats")
            ScrollView {
                
                
                Chart(monthlyData) { data in
                    BarMark(
                        x: .value("Month", data.month),
                        y: .value("Count", data.count)
                    )
                    .foregroundStyle(data.color)
                    .annotation(position: .overlay) {
                        if data.count > 0 {
                            Text("\(data.count)")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .cornerRadius(4)
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        AxisTick()
                        AxisValueLabel() {
                            if let intValue = value.as(Int.self) {
                                Text("\(intValue)")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel() {
                            if let strValue = value.as(String.self) {
                                Text(strValue)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .chartLegend(position: .bottom)
                .frame(height: 300)
                // Add these modifiers to control bar width and spacing
                .chartPlotStyle { plotArea in
                    plotArea
                        .background(.clear)
                }
                // Set the bar width to be wider
                .chartYScale(range: .plotDimension(padding: 20))
                .chartXScale(range: .plotDimension(padding: 40))
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}

struct MonthlyData: Identifiable {
    let id = UUID()
    let monthNumber: Int  // For sorting
    let month: String    // For display
    let outcome: String
    let count: Int
    let color: Color
}
