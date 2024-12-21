import SwiftUI
import Combine
import Charts

@MainActor
final class InspectorProfileViewModel: ObservableObject {
    @Published var profile: InspectorProfile
    let reports: [Report]
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()
    
    @Published var recentReports: [Report]
    @Published var themeStatistics: ThemeStatistics
    @Published var themeAnalytics: ThemeAnalyzer.InspectorThemeAnalytics?
    @Published private(set) var sortedGrades: [(key: String, value: Int)] = []
    @Published private(set) var authorities: [String] = []
    @Published var totalInspections: Int = 0
    @Published private(set) var isLoadingThemes: Bool = false
    
    init(profile: InspectorProfile, reports: [Report]) {
        self.profile = profile
        self.reports = reports
        self.themeStatistics = ThemeStatistics(total: 0, topThemes: [], percentages: [:])
        
        let filteredReports = reports
            .filter { $0.inspector == profile.name }
            .sorted { report1, report2 in
                let formatter = DateFormatter()
                formatter.dateFormat = "dd/MM/yyyy"
                let date1 = formatter.date(from: report1.date) ?? Date.distantPast
                let date2 = formatter.date(from: report2.date) ?? Date.distantPast
                return date1 > date2
            }
        self.recentReports = filteredReports
        
        calculateStats()
    }
    
    func loadThemeAnalytics() async {
        guard themeAnalytics == nil else { return }
        
        isLoadingThemes = true
        defer { isLoadingThemes = false }
        
        await Task.yield()
        self.themeAnalytics = await ThemeAnalyzer.calculateInspectorThemeAnalytics(from: reports, for: profile.name)
    }
    
    private func calculateStats() {
        totalInspections = recentReports.count
        
        var gradeCount: [String: Int] = [:]
        for report in recentReports {
            if let overallRating = report.ratings.first(where: { $0.category == "Overall effectiveness" })?.rating {
                gradeCount[overallRating, default: 0] += 1
            } else {
                gradeCount[report.outcome, default: 0] += 1
            }
        }
        sortedGrades = gradeCount.sorted { $0.key < $1.key }
        
        authorities = Array(profile.authorities.keys.sorted())
    }
    
    func authorityCount(_ authority: String) -> Int {
        profile.authorities[authority] ?? 0
    }
    
    func calculatePercentage(_ count: Int) -> Int {
        guard totalInspections > 0 else { return 0 }
        return Int(round(Double(count) / Double(totalInspections) * 100))
    }
    
    func generatePDF() -> URL? {
        let renderer = PDFRenderer(profile: profile, reports: reports)
        return renderer.renderPDF()
    }
}
