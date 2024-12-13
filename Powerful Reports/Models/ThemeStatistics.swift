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
//class ThemeAnalyzer {
//    // Original methods for Local Authority
//    static func analyzeThemes(from reports: [Report], for localAuthority: String) -> [ThemeFrequency] {
//        var themeCounts: [String: Int] = [:]
//        
//        let areaReports = reports.filter { $0.localAuthority == localAuthority }
//        
//        for report in areaReports {
//            for theme in report.themes {
//                themeCounts[theme.topic, default: 0] += 1
//            }
//        }
//        
//        let sortedThemes = themeCounts.map { topic, count in
//            ThemeFrequency(topic: topic, count: count)
//        }.sorted { $0.count > $1.count }
//        
//        return sortedThemes
//    }
//    
//    static func getThemeStatistics(from reports: [Report], for areaId: String) -> (total: Int, topThemes: [ThemeFrequency], percentages: [String: Double]) {
//        let themeFrequencies = analyzeThemes(from: reports, for: areaId)
//        let totalThemeOccurrences = themeFrequencies.reduce(0) { $0 + $1.count }
//        
//        var percentages: [String: Double] = [:]
//        themeFrequencies.forEach { theme in
//            percentages[theme.topic] = Double(theme.count) / Double(totalThemeOccurrences) * 100
//        }
//        
//        return (
//            total: totalThemeOccurrences,
//            topThemes: themeFrequencies,
//            percentages: percentages
//        )
//    }
//    
//    // New methods for Inspector
//    static func analyzeThemesByInspector(from reports: [Report], for inspector: String) -> [ThemeFrequency] {
//        var themeCounts: [String: Int] = [:]
//        
//        let inspectorReports = reports.filter { $0.inspector == inspector }
//        
//        for report in inspectorReports {
//            for theme in report.themes {
//                themeCounts[theme.topic, default: 0] += 1
//            }
//        }
//        
//        let sortedThemes = themeCounts.map { topic, count in
//            ThemeFrequency(topic: topic, count: count)
//        }.sorted { $0.count > $1.count }
//        
//        return sortedThemes
//    }
//    
//    static func getInspectorThemeStatistics(from reports: [Report], for inspector: String) -> (total: Int, topThemes: [ThemeFrequency], percentages: [String: Double]) {
//        let themeFrequencies = analyzeThemesByInspector(from: reports, for: inspector)
//        let totalThemeOccurrences = themeFrequencies.reduce(0) { $0 + $1.count }
//        
//        var percentages: [String: Double] = [:]
//        themeFrequencies.forEach { theme in
//            percentages[theme.topic] = Double(theme.count) / Double(totalThemeOccurrences) * 100
//        }
//        
//        return (
//            total: totalThemeOccurrences,
//            topThemes: themeFrequencies,
//            percentages: percentages
//        )
//    }
//}
