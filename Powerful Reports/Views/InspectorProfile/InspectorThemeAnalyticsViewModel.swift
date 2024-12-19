import SwiftUI
import Combine
import Charts

@MainActor
final class InspectorThemeAnalyticsViewModel: ObservableObject {
    private let analytics: ThemeAnalyzer.InspectorThemeAnalytics
    
    private func matchesRating(_ report: (rating: String, reportId: String, location: String), rating: String) -> Bool {
        switch rating {
        case "All":
            return true
        case "Outstanding":
            return report.rating.hasPrefix("Outstanding")
        case "Good":
            return report.rating.hasPrefix("Good")
        case "Requires Improvement":
            return report.rating.hasPrefix("Requires Improvement")
        case "Inadequate":
            return report.rating.hasPrefix("Inadequate")
        case "Met":
            return report.rating == "Met"
        case "Not Met":
            return report.rating == "Not Met"
        default:
            return false
        }
    }
    
    func availableRatings(forLocation location: String?) -> [String] {
        var ratings = Set<String>()
        var seenReportIds = Set<String>()
        
        for correlation in analytics.themeOutcomeCorrelations {
            for report in correlation.ratingReports {
                if seenReportIds.contains(report.reportId) {
                    continue
                }
                
                if let location = location, report.location != location {
                    continue
                }
                
                if report.rating.hasPrefix("Outstanding") {
                    ratings.insert("Outstanding")
                } else if report.rating.hasPrefix("Good") {
                    ratings.insert("Good")
                } else if report.rating.hasPrefix("Requires Improvement") {
                    ratings.insert("Requires Improvement")
                } else if report.rating.hasPrefix("Inadequate") {
                    ratings.insert("Inadequate")
                }
                
                if report.rating == "Met" {
                    ratings.insert("Met")
                }
                if report.rating == "Not Met" {
                    ratings.insert("Not Met")
                }
                
                seenReportIds.insert(report.reportId)
            }
        }
        
        var result = ["All"]
        result.append(contentsOf: ratings.sorted())
        return result
    }
    
    func availableLocations(forRating rating: String) -> Set<String> {
        var locations = Set<String>()
        var seenReportIds = Set<String>()
        
        for correlation in analytics.themeOutcomeCorrelations {
            for report in correlation.ratingReports {
                if seenReportIds.contains(report.reportId) {
                    continue
                }
                
                if matchesRating(report, rating: rating) {
                    locations.insert(report.location)
                    seenReportIds.insert(report.reportId)
                }
            }
        }
        
        return locations
    }
    
    var uniqueLocations: Set<String> {
        analytics.locations
    }
    
    init(analytics: ThemeAnalyzer.InspectorThemeAnalytics) {
        self.analytics = analytics
    }
    
    func filteredCorrelations(
        percentageRange: InspectorThemeAnalyticsView.PercentageRange,
        rating: String,
        location: String?,
        showMetOnly: Bool
    ) -> (correlations: [ThemeAnalyzer.ThemeCorrelation], themes: [(theme: String, count: Int)]) {
        // First filter by original percentage range
        let percentageFiltered = analytics.themeOutcomeCorrelations.filter { correlation in
            percentageRange.range == nil ||
                percentageRange.range!.contains(correlation.percentage)
        }
        
        // Count total reports that match the rating and location filters
        let totalFilteredReports = Set(percentageFiltered.flatMap { correlation in
            correlation.ratingReports.filter { report in
                let matchesRating = matchesRating(report, rating: rating)
                
                let matchesLocation = location == nil || report.location == location
                
                return matchesRating && matchesLocation
            }.map { $0.reportId }
        }).count
        
        // Then filter by rating and location and count matching reports
        let filtered = percentageFiltered.compactMap { correlation -> ThemeAnalyzer.ThemeCorrelation? in
            // Count reports that match both rating and location filters
            let matchingReports = correlation.ratingReports.filter { report in
                let matchesRating = matchesRating(report, rating: rating)
                
                let matchesLocation = location == nil || report.location == location
                
                return matchesRating && matchesLocation
            }
            
            let matchingReportCount = matchingReports.count
            if matchingReportCount == 0 { return nil } // Filter out themes with no matching reports
            
            // Create updated correlation with new percentage based on matching reports
            var updatedCorrelation = correlation
            updatedCorrelation.percentage = totalFilteredReports > 0 ? (Double(matchingReportCount) / Double(totalFilteredReports)) * 100 : 0
            return updatedCorrelation
        }
        
        // Calculate theme counts based on the filtered reports
        var themeCounts: [String: Int] = [:]
        for correlation in filtered {
            let matchingReports = correlation.ratingReports.filter { report in
                let matchesRating = matchesRating(report, rating: rating)
                
                let matchesLocation = location == nil || report.location == location
                
                return matchesRating && matchesLocation
            }
            themeCounts[correlation.theme] = matchingReports.count
        }
        
        let sortedThemes = themeCounts.map { (theme: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
        
        return (
            correlations: filtered.sorted { $0.percentage > $1.percentage },
            themes: sortedThemes
        )
    }
}
