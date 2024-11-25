//
//  AnnualStats.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 25/11/2024.
//

import SwiftUI
import Charts
extension InspectionReportsViewModel {
    func getGradesByMonth() -> [(month: String, grades: [String: Int])] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM yyyy"
        let calendar = Calendar.current
        let now = Date()
        
        var monthlyGrades: [(month: String, grades: [String: Int])] = []
        
        for month in 0...12 {
            guard let monthDate = calendar.date(byAdding: .month, value: -month, to: now) else { continue }
            let monthStart = calendar.startOfMonth(for: monthDate)
            let monthEnd = calendar.endOfMonth(for: monthDate)
            
            let monthReports = reports.filter { report in
                guard let reportDate = dateFormatter.date(from: report.date) else { return false }
                return reportDate >= monthStart && reportDate <= monthEnd
            }
            
            var grades: [String: Int] = [:]
            for report in monthReports {
                if let rating = report.overallRating {
                    print("Report with rating: \(rating)")
                    grades[rating, default: 0] += 1
                } else if !report.outcome.isEmpty {
                    print("Report with outcome: \(report.outcome)")
                    grades[report.outcome, default: 0] += 1
                }
            }
            
            print("CALENDWAR_Month: \(monthDate.monthYearString), Grades: \(grades)")
            monthlyGrades.append((month: monthDate.monthYearString, grades: grades))
        }
        
        return monthlyGrades.reversed()
    }
}
struct AnnualStats: View {
    @ObservedObject var viewModel: InspectionReportsViewModel
    
    var body: some View {
        VStack{
            Text("33")
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
    }
    
   
}


