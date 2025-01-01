import Foundation

struct ThemeFrequency: Identifiable {
    let id = UUID()
    let topic: String
    let count: Int
}

struct ThemeStatistics {
    let total: Int
    let topThemes: [ThemeFrequency]
    let percentages: [String: Double]
}

class ThemeAnalyzer {
    // Original methods for Local Authority
    static func analyzeThemes(from reports: [Report], for localAuthority: String) -> [ThemeFrequency] {
        var themeCounts: [String: Int] = [:]
        
        let authorityReports = reports.filter { $0.localAuthority == localAuthority }
        
        for report in authorityReports {
            for theme in report.themes {
                themeCounts[theme.topic, default: 0] += 1
            }
        }
        
        let sortedThemes = themeCounts.map { topic, count in
            ThemeFrequency(topic: topic, count: count)
        }.sorted { $0.count > $1.count }
        
        return sortedThemes
    }
    
    static func getThemeStatistics(from reports: [Report], for authorityId: String) -> ThemeStatistics {
        let themeFrequencies = analyzeThemes(from: reports, for: authorityId)
        let totalThemeOccurrences = themeFrequencies.reduce(0) { $0 + $1.count }
        
        var percentages: [String: Double] = [:]
        themeFrequencies.forEach { theme in
            percentages[theme.topic] = Double(theme.count) / Double(totalThemeOccurrences) * 100
        }
        
        return ThemeStatistics(
            total: totalThemeOccurrences,
            topThemes: themeFrequencies,
            percentages: percentages
        )
    }
    
    // Methods for Inspector
    static func analyzeThemesByInspector(from reports: [Report], for inspector: String) -> [ThemeFrequency] {
        var themeCounts: [String: Int] = [:]
        
        let inspectorReports = reports.filter { $0.inspector == inspector }
        
        for report in inspectorReports {
            for theme in report.themes {
                themeCounts[theme.topic, default: 0] += 1
            }
        }
        
        let sortedThemes = themeCounts.map { topic, count in
            ThemeFrequency(topic: topic, count: count)
        }.sorted { $0.count > $1.count }
        
        return sortedThemes
    }
    
    static func getInspectorThemeStatistics(from reports: [Report], for inspector: String) -> ThemeStatistics {
        let themeFrequencies = analyzeThemesByInspector(from: reports, for: inspector)
        let totalThemeOccurrences = themeFrequencies.reduce(0) { $0 + $1.count }
        
        var percentages: [String: Double] = [:]
        themeFrequencies.forEach { theme in
            percentages[theme.topic] = Double(theme.count) / Double(totalThemeOccurrences) * 100
        }
        
        return ThemeStatistics(
            total: totalThemeOccurrences,
            topThemes: themeFrequencies,
            percentages: percentages
        )
    }
}

// Theme correlation and combination analysis
extension ThemeAnalyzer {
    struct ThemeCorrelation: Identifiable {
        let id = UUID()
        let theme: String
        var percentage: Double
        let outcome: String
        let ratingValue: RatingValue
        let ratings: [String]
        let ratingReports: [(rating: String, reportId: String, location: String)]
        let locations: [String]
        
        init(theme: String, percentage: Double, outcome: String = "", ratingValue: RatingValue = .none, ratings: [String] = [], ratingReports: [(rating: String, reportId: String, location: String)], locations: [String]) {
            self.theme = theme
            self.percentage = percentage
            self.outcome = outcome
            self.ratingValue = ratingValue
            self.ratings = ratings
            self.ratingReports = ratingReports
            self.locations = locations
        }
    }
    
    struct ThemeFrequencyStats: Identifiable {
        let id = UUID()
        let theme: String
        let count: Int
    }
    
    struct ThemePair: Hashable {
        let theme1: String
        let theme2: String
    }
    
    struct ThemePairStatistic {
        let pair: ThemePair
        let count: Int
        let percentage: Double
    }
    
    struct InspectorThemeAnalytics {
        let averageThemesPerReport: Double
        let themeOutcomeCorrelations: [ThemeCorrelation]
        let frequentThemes: [ThemeFrequencyStats]
        let themesByProvisionType: [String: Int]
        let locations: Set<String>
        let totalReports: Int
    }

    struct AuthorityThemeAnalytics {
        let averageThemesPerReport: Double
        let themeOutcomeCorrelations: [ThemeCorrelation]
        let frequentThemes: [ThemeFrequencyStats]
        let themesByProvisionType: [String: Int]
        let inspectors: Set<String>
        let totalReports: Int
    }

    static func calculateInspectorThemeAnalytics(from allReports: [Report], for inspector: String) async -> InspectorThemeAnalytics {
        return await withCheckedContinuation { continuation in
            Task.detached(priority: .background) {
                let inspectorReports = allReports.filter { $0.inspector == inspector }
                let totalReports = inspectorReports.count
                
                // Track theme occurrences and their ratings
                var themeReports: [String: Set<String>] = [:]
                var themeRatings: [String: [(rating: String, reportId: String, location: String)]] = [:]
                var themeLocations: [String: Set<String>] = [:]
                var themesByType: [String: [String: Int]] = [:]
                
                // Process reports in chunks to avoid UI freezes
                let chunkSize = 5
                for chunk in stride(from: 0, to: inspectorReports.count, by: chunkSize) {
                    let endIndex = min(chunk + chunkSize, inspectorReports.count)
                    let reportsChunk = inspectorReports[chunk..<endIndex]
                    
                    for report in reportsChunk {
                        // Track themes by provision type
                        if themesByType[report.typeOfProvision] == nil {
                            themesByType[report.typeOfProvision] = [:]
                        }
                        
                        for theme in report.themes {
                            // Get or create theme report IDs set
                            if themeReports[theme.topic] == nil {
                                themeReports[theme.topic] = Set<String>()
                            }
                            themeReports[theme.topic]?.insert(report.id)
                            
                            // Get or create theme ratings array
                            if themeRatings[theme.topic] == nil {
                                themeRatings[theme.topic] = []
                            }
                            
                            // Add rating info
                            let rating = report.ratings.first(where: { $0.category == "Overall effectiveness" })?.rating ?? report.outcome
                            themeRatings[theme.topic]?.append((rating: rating, reportId: report.id, location: report.localAuthority))
                            
                            // Track locations
                            if themeLocations[theme.topic] == nil {
                                themeLocations[theme.topic] = Set<String>()
                            }
                            themeLocations[theme.topic]?.insert(report.localAuthority)
                            
                            // Track themes by type
                            themesByType[report.typeOfProvision]?[theme.topic, default: 0] += 1
                        }
                    }
                }
                
                // Calculate correlations
                var correlations: [ThemeCorrelation] = []
                for (theme, reportIds) in themeReports {
                    let percentage = (Double(reportIds.count) / Double(totalReports)) * 100
                    let ratings = themeRatings[theme] ?? []
                    let locations = Array(themeLocations[theme] ?? Set())
                    
                    // Calculate most common rating
                    var ratingCounts: [String: Int] = [:]
                    for ratingReport in ratings {
                        ratingCounts[ratingReport.rating, default: 0] += 1
                    }
                    let mostCommonRating = ratingCounts.max(by: { $0.value < $1.value })?.key ?? ""
                    
                    correlations.append(ThemeCorrelation(
                        theme: theme,
                        percentage: percentage,
                        outcome: mostCommonRating,
                        ratingValue: RatingValue(rawValue: mostCommonRating) ?? .none,
                        ratings: Array(Set(ratings.map { $0.rating })),
                        ratingReports: ratings,
                        locations: locations
                    ))
                }
                
                // Sort correlations by percentage
                correlations.sort { $0.percentage > $1.percentage }
                
                // Calculate frequent themes
                let frequentThemes = themeReports.map { theme, reports in
                    ThemeFrequencyStats(theme: theme, count: reports.count)
                }.sorted { 
                    if $0.count == $1.count {
                        return $0.theme < $1.theme // Secondary sort by theme name when counts are equal
                    }
                    return $0.count > $1.count // Primary sort by count
                }
                
                let locations = Set(inspectorReports.map { $0.localAuthority })
                let averageThemes = Double(inspectorReports.reduce(0) { $0 + $1.themes.count }) / Double(totalReports)
                
                let analytics = InspectorThemeAnalytics(
                    averageThemesPerReport: averageThemes,
                    themeOutcomeCorrelations: correlations,
                    frequentThemes: frequentThemes,
                    themesByProvisionType: themesByType.mapValues { $0.count },
                    locations: locations,
                    totalReports: totalReports
                )
                
                continuation.resume(returning: analytics)
            }
        }
    }
    
    static func calculateAuthorityThemeAnalytics(from allReports: [Report], for authority: String) async -> AuthorityThemeAnalytics {
        return await withCheckedContinuation { continuation in
            Task.detached(priority: .background) {
                let authorityReports = allReports.filter { $0.localAuthority == authority }
                let totalReports = authorityReports.count
                
                // Track theme occurrences and their ratings
                var themeReports: [String: Set<String>] = [:]
                var themeRatings: [String: [(rating: String, reportId: String, inspector: String)]] = [:]
                var themeInspectors: [String: Set<String>] = [:]
                var themesByType: [String: [String: Int]] = [:]
                
                // Process reports in chunks to avoid UI freezes
                let chunkSize = 5
                for chunk in stride(from: 0, to: authorityReports.count, by: chunkSize) {
                    let endIndex = min(chunk + chunkSize, authorityReports.count)
                    let reportsChunk = authorityReports[chunk..<endIndex]
                    
                    for report in reportsChunk {
                        // Track themes by provision type
                        if themesByType[report.typeOfProvision] == nil {
                            themesByType[report.typeOfProvision] = [:]
                        }
                        
                        for theme in report.themes {
                            // Get or create theme report IDs set
                            if themeReports[theme.topic] == nil {
                                themeReports[theme.topic] = Set<String>()
                            }
                            themeReports[theme.topic]?.insert(report.id)
                            
                            // Get or create theme ratings array
                            if themeRatings[theme.topic] == nil {
                                themeRatings[theme.topic] = []
                            }
                            
                            // Add rating info
                            let rating = report.ratings.first(where: { $0.category == "Overall effectiveness" })?.rating ?? report.outcome
                            themeRatings[theme.topic]?.append((rating: rating, reportId: report.id, inspector: report.inspector))
                            
                            // Track inspectors
                            if themeInspectors[theme.topic] == nil {
                                themeInspectors[theme.topic] = Set<String>()
                            }
                            themeInspectors[theme.topic]?.insert(report.inspector)
                            
                            // Track themes by type
                            themesByType[report.typeOfProvision]?[theme.topic, default: 0] += 1
                        }
                    }
                }
                
                // Calculate correlations
                var correlations: [ThemeCorrelation] = []
                for (theme, reportIds) in themeReports {
                    let percentage = (Double(reportIds.count) / Double(totalReports)) * 100
                    let ratings = themeRatings[theme] ?? []
                    let inspectors = Array(themeInspectors[theme] ?? Set())
                    
                    // Calculate most common rating
                    var ratingCounts: [String: Int] = [:]
                    for ratingReport in ratings {
                        ratingCounts[ratingReport.rating, default: 0] += 1
                    }
                    let mostCommonRating = ratingCounts.max(by: { $0.value < $1.value })?.key ?? ""
                    
                    let correlation = ThemeCorrelation(
                        theme: theme,
                        percentage: percentage,
                        outcome: mostCommonRating,
                        ratingValue: RatingValue(rawValue: mostCommonRating) ?? .none,
                        ratings: Array(Set(ratings.map { $0.rating })),
                        ratingReports: ratings.map { ($0.rating, $0.reportId, $0.inspector) },
                        locations: inspectors
                    )
                    correlations.append(correlation)
                }
                
                // Sort correlations by percentage
                correlations.sort { $0.percentage > $1.percentage }
                
                // Calculate frequent themes
                let frequentThemes = themeReports.map { theme, reports in
                    ThemeFrequencyStats(theme: theme, count: reports.count)
                }.sorted { $0.count > $1.count }
                
                // Calculate average themes per report
                let totalThemes = authorityReports.reduce(0) { $0 + $1.themes.count }
                let averageThemes = Double(totalThemes) / Double(totalReports)
                
                let analytics = AuthorityThemeAnalytics(
                    averageThemesPerReport: averageThemes,
                    themeOutcomeCorrelations: correlations,
                    frequentThemes: frequentThemes,
                    themesByProvisionType: themesByType.mapValues { $0.count },
                    inspectors: Set(authorityReports.map { $0.inspector }),
                    totalReports: totalReports
                )
                
                continuation.resume(returning: analytics)
            }
        }
    }
    
    static func calculateAverageThemeScore(correlations: [ThemeCorrelation]) -> Double {
        // TO DO: implement average theme score calculation
        return 0.0
    }
    
    static func getInspectorThemeAnalytics(from reports: [Report], for inspector: String) async -> InspectorThemeAnalytics {
        return await calculateInspectorThemeAnalytics(from: reports, for: inspector)
    }
    
    static func getAuthorityThemeAnalytics(from reports: [Report], for authority: String) async -> AuthorityThemeAnalytics {
        return await calculateAuthorityThemeAnalytics(from: reports, for: authority)
    }
}
