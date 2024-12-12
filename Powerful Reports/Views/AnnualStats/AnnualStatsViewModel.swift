import SwiftUI
import Foundation

struct MonthlyInspectionCount {
    let month: String
    let count: Int
    let date: Date
}

@MainActor
class AnnualStatsViewModel: ObservableObject {
    @Published private(set) var monthlyStats: [MonthlyInspectionCount] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()
    
    private let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()
    
    func loadData(from reports: [Report]) {
        isLoading = true
        defer { isLoading = false }
        
        let counts = Dictionary(grouping: reports) { report in
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
        .suffix(12)
        
        monthlyStats = Array(counts)
    }
}
