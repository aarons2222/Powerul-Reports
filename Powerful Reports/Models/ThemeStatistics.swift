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
        
        let areaReports = reports.filter { $0.localAuthority == localAuthority }
        
        for report in areaReports {
            for theme in report.themes {
                themeCounts[theme.topic, default: 0] += 1
            }
        }
        
        let sortedThemes = themeCounts.map { topic, count in
            ThemeFrequency(topic: topic, count: count)
        }.sorted { $0.count > $1.count }
        
        return sortedThemes
    }
    
    static func getThemeStatistics(from reports: [Report], for areaId: String) -> ThemeStatistics {
        let themeFrequencies = analyzeThemes(from: reports, for: areaId)
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
        let outcome: String // This will be either the outcome text or the grade check value
        var percentage: Double
        let ratingValue: RatingValue // Using the same RatingValue enum from AllReportsView
        let location: String
        let ratings: [String]
        let ratingReports: [(rating: String, reportId: String, location: String)]
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
    
    static func calculateInspectorThemeAnalytics(from allReports: [Report], for inspector: String) -> InspectorThemeAnalytics {
        let inspectorReports = allReports.filter { $0.inspector == inspector }
        let totalReports = inspectorReports.count
        
        print("Total reports for inspector \(inspector): \(inspectorReports.count)")
        
        // Track theme occurrences and their ratings
        var themeReports: [String: Set<String>] = [:] // theme -> set of report IDs
        var themeRatings: [String: [(rating: String, reportId: String, location: String)]] = [:]
        var themeLocations: [String: Set<String>] = [:]
        
        for report in inspectorReports {
            // Get unique themes in this report
            let uniqueThemes = Set(report.themes.map { $0.topic })
            
            // Track report for each theme
            for theme in uniqueThemes {
                themeReports[theme, default: []].insert(report.id)
                
                // Get rating for this theme
                let rating: String
                if let overallRating = report.overallRating {
                    rating = overallRating
                } else if !report.outcome.isEmpty {
                    rating = report.outcome
                } else {
                    rating = ""
                }
                
                themeRatings[theme, default: []].append((rating: rating, reportId: report.id, location: report.localAuthority))
                
                if !report.localAuthority.isEmpty {
                    themeLocations[theme, default: []].insert(report.localAuthority)
                }
            }
        }
        
        // Calculate correlations
        let correlations = themeReports.map { theme, reportIds in
            let reportCount = Double(reportIds.count)
            let percentage = (reportCount / Double(totalReports)) * 100
            
            // Get most common rating for this theme
            let ratings = themeRatings[theme] ?? []
            var ratingCounts: [String: Int] = [:]
            for rating in ratings {
                ratingCounts[rating.rating, default: 0] += 1
            }
            let mostCommonRating = ratingCounts.max(by: { $0.value < $1.value })?.key ?? ""
            
            let correlation = ThemeCorrelation(
                theme: theme,
                outcome: mostCommonRating,
                percentage: percentage,
                ratingValue: RatingValue(rawValue: mostCommonRating) ?? .none,
                location: Array(themeLocations[theme] ?? []).first ?? "",
                ratings: Array(Set(ratings.map { $0.rating })),
                ratingReports: ratings
            )
            
            print("Theme: \(theme)")
            print("- Appears in \(reportIds.count) out of \(totalReports) reports")
            print("- Percentage: \(percentage)%")
            print("- Reports by rating: \(ratings.map { $0.rating })")
            
            return correlation
        }
        .sorted { $0.percentage > $1.percentage }
        
        // Calculate themes by provision type
        var themesByType: [String: [String: Int]] = [:]
        for report in inspectorReports {
            if themesByType[report.typeOfProvision] == nil {
                themesByType[report.typeOfProvision] = [:]
            }
            for theme in report.themes {
                themesByType[report.typeOfProvision]?[theme.topic, default: 0] += 1
            }
        }
        
        let themesByProvisionType = themesByType.mapValues { themeCounts in
            themeCounts.map { ThemeFrequency(topic: $0, count: $1) }
                .sorted { $0.count > $1.count }
        }
        
        // Calculate average themes per report
        let averageThemes = Double(inspectorReports.reduce(0) { $0 + $1.themes.count }) / Double(totalReports)
        
        // Calculate theme pairs
        var themePairCounts: [ThemePair: Int] = [:]
        for report in inspectorReports {
            let themes = report.themes.map { $0.topic }
            for i in 0..<themes.count {
                for j in (i+1)..<themes.count {
                    let pair = ThemePair(
                        theme1: min(themes[i], themes[j]),
                        theme2: max(themes[i], themes[j])
                    )
                    themePairCounts[pair, default: 0] += 1
                }
            }
        }
        
        // Calculate theme pairs in other reports for comparison
        var otherThemePairCounts: [ThemePair: Int] = [:]
        for report in allReports.filter({ $0.inspector != inspector }) {
            let themes = report.themes.map { $0.topic }
            for i in 0..<themes.count {
                for j in (i+1)..<themes.count {
                    let pair = ThemePair(
                        theme1: min(themes[i], themes[j]),
                        theme2: max(themes[i], themes[j])
                    )
                    otherThemePairCounts[pair, default: 0] += 1
                }
            }
        }
        
        // Find common and unique theme pairs
        let totalInspectorPairs = Double(themePairCounts.values.reduce(0, +))
        let commonPairs = themePairCounts.map { pair, count in
            ThemePairStatistic(
                pair: pair,
                count: count,
                percentage: Double(count) / totalInspectorPairs * 100
            )
        }.sorted { $0.count > $1.count }
        
        // Unique combinations are those that appear more frequently for this inspector
        let uniquePairs = themePairCounts.compactMap { pair, count -> ThemePairStatistic? in
            let otherCount = otherThemePairCounts[pair] ?? 0
            let inspectorFrequency = Double(count) / Double(inspectorReports.count)
            let otherFrequency = Double(otherCount) / Double(allReports.filter({ $0.inspector != inspector }).count)
            
            if inspectorFrequency > otherFrequency * 2 { // At least twice as frequent
                return ThemePairStatistic(
                    pair: pair,
                    count: count,
                    percentage: Double(count) / totalInspectorPairs * 100
                )
            }
            return nil
        }.sorted { $0.count > $1.count }
        
        // Calculate frequent themes
        let frequentThemes = inspectorReports.flatMap { $0.themes }.reduce(into: [:]) { $0[$1.topic, default: 0] += 1 }
            .map { ThemeFrequencyStats(theme: $0, count: $1) }
            .sorted { $0.count > $1.count }
        
        return InspectorThemeAnalytics(
            averageThemesPerReport: averageThemes,
            themeOutcomeCorrelations: correlations,
            frequentThemes: Array(frequentThemes.prefix(10)),
            themesByProvisionType: themesByProvisionType.mapValues { $0.count },
            locations: Set(inspectorReports.compactMap { $0.localAuthority }),
            totalReports: totalReports
        )
    }
}
