import SwiftUI

class AuthorityThemeAnalyticsViewModel: ObservableObject {
    let analytics: ThemeAnalyzer.AuthorityThemeAnalytics
    var uniqueInspectors: Set<String> = []
    
    // Available options based on authority data
    var availableRatings: [String] {
        var ratings = Set<String>()
        for correlation in analytics.themeOutcomeCorrelations {
            ratings.insert(correlation.outcome)
        }
        return ["All"] + Array(ratings).sorted()
    }
    
    init(analytics: ThemeAnalyzer.AuthorityThemeAnalytics) {
        self.analytics = analytics
        self.uniqueInspectors = analytics.inspectors // Using inspectors instead of locations for authorities
    }
    
    func filteredCorrelations(
        percentageRange: AuthorityThemeAnalyticsView.PercentageRange,
        rating: String,
        location: String?,
        showMetOnly: Bool
    ) -> (correlations: [ThemeAnalyzer.ThemeCorrelation], themes: [(theme: String, count: Int)]) {
        // Filter correlations based on percentage range
        var filteredCorrelations = analytics.themeOutcomeCorrelations
        
        if let range = percentageRange.range {
            filteredCorrelations = filteredCorrelations.filter { correlation in
                range.contains(correlation.percentage)
            }
        }
        
        // Filter by rating if not "All"
        if rating != "All" {
            filteredCorrelations = filteredCorrelations.filter { correlation in
                correlation.outcome == rating
            }
        }
        
        // Filter by inspector if selected
        if let inspector = location {
            filteredCorrelations = filteredCorrelations.filter { correlation in
                correlation.ratingReports.contains { report in
                    report.location == inspector // location is inspector in this context
                }
            }
        }
        
        // Calculate theme frequencies
        var themeFrequencies: [String: Int] = [:]
        for correlation in filteredCorrelations {
            themeFrequencies[correlation.theme, default: 0] += correlation.ratingReports.count
        }
        
        let sortedThemes = themeFrequencies.map { (theme: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
        
        return (correlations: filteredCorrelations, themes: sortedThemes)
    }
}
