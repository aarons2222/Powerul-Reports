import SwiftUI
import Combine
import Charts

@MainActor
final class InspectorProfileViewModel: ObservableObject {
    let profile: InspectorProfile
    let reports: [Report]
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }()
    
    @Published private(set) var recentReports: [Report] = []
    @Published var themeStatistics: ThemeStatistics
    @Published private(set) var sortedGrades: [(key: String, value: Int)] = []
    @Published private(set) var areas: [String] = []
    @Published private(set) var themeAnalytics: ThemeAnalyzer.InspectorThemeAnalytics?
    
    init(profile: InspectorProfile, reports: [Report]) {
        self.profile = profile
        self.reports = reports
        self.themeStatistics = ThemeStatistics(total: 0, topThemes: [], percentages: [:])
        loadData()
    }
    
    private func loadData() {
        // Recent Reports
        recentReports = reports
            .filter { $0.inspector == profile.name }
            .sorted { report1, report2 in
                let date1 = dateFormatter.date(from: report1.date) ?? Date.distantPast
                let date2 = dateFormatter.date(from: report2.date) ?? Date.distantPast
                return date1 > date2
            }
        
        // Theme Statistics
        themeStatistics = ThemeAnalyzer.getInspectorThemeStatistics(from: reports, for: profile.name)
        
        // Theme Analytics
        themeAnalytics = ThemeAnalyzer.calculateInspectorThemeAnalytics(from: reports, for: profile.name)
        
        // Sorted Grades
        sortedGrades = profile.grades.sorted(by: { $0.value > $1.value })
        
        // Areas
        areas = Array(profile.areas.keys.sorted())
    }
    
    func areaCount(_ area: String) -> Int {
        profile.areas[area] ?? 0
    }
    
    func calculatePercentage(_ count: Int) -> Int {
        guard profile.totalInspections > 0 else { return 0 }
        return Int(round(Double(count) / Double(profile.totalInspections) * 100))
    }
    
    func generatePDF() -> URL? {
        let renderer = PDFRenderer(profile: profile, reports: reports)
        return renderer.renderPDF()
    }
}
