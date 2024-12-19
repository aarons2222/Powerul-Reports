import SwiftUI
import Charts

struct InspectorThemeAnalyticsView: View {
    let analytics: ThemeAnalyzer.InspectorThemeAnalytics
    let inspectorName: String
    @State private var showingAverageInfo = false
    @State private var showingCorrelationsInfo = false
    @State private var showingThemesInfo = false
    @State private var selectedPercentageRange = PercentageRange.all
    @State private var selectedRating: String = "All"
    @State private var selectedLocation: String? = nil
    @State private var showMetOnly = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    enum PercentageRange: String, CaseIterable {
        case all = "All"
        case seventyFiveToHundred = "75-100%"
        case fiftyToSeventyFive = "50-75%"
        case twentyFiveToFifty = "25-50%"
        case zeroToTwentyFive = "0-25%"
        
        var range: ClosedRange<Double>? {
            switch self {
            case .all: return nil
            case .seventyFiveToHundred: return 75...100
            case .fiftyToSeventyFive: return 50...75
            case .twentyFiveToFifty: return 25...50
            case .zeroToTwentyFive: return 0...25
            }
        }
    }
    
    let ratingOptions = [
        "All",
        "Outstanding",
        "Good",
        "Requires Improvement",
        "Inadequate",
        "Met",
        "Not Met"
    ]
    
    var filteredCorrelations: [ThemeAnalyzer.ThemeCorrelation] {
        // First filter by original percentage range
        let percentageFiltered = analytics.themeOutcomeCorrelations.filter { correlation in
            selectedPercentageRange.range == nil ||
                selectedPercentageRange.range!.contains(correlation.percentage)
        }
        
        // Count total reports that match the rating and location filters
        let totalFilteredReports = Set(percentageFiltered.flatMap { correlation in
            correlation.ratingReports.filter { report in
                let matchesRating = switch selectedRating {
                    case "All": true
                    case "Outstanding": report.rating.hasPrefix("Outstanding")
                    case "Good": report.rating.hasPrefix("Good")
                    case "Requires Improvement": report.rating.hasPrefix("Requires Improvement")
                    case "Inadequate": report.rating.hasPrefix("Inadequate")
                    case "Met": report.rating.hasPrefix("Outstanding") || report.rating.hasPrefix("Good") || report.rating == "Met"
                    case "Not Met": report.rating.hasPrefix("Requires Improvement") || report.rating.hasPrefix("Inadequate") || report.rating == "Not Met"
                    default: false
                }
                
                let matchesLocation = selectedLocation == nil || report.location == selectedLocation
                
                return matchesRating && matchesLocation
            }.map { $0.reportId }
        }).count
        
        // Then filter by rating and location and count matching reports
        let filtered = percentageFiltered.compactMap { correlation -> ThemeAnalyzer.ThemeCorrelation? in
            // Count reports that match both rating and location filters
            let matchingReports = correlation.ratingReports.filter { report in
                let matchesRating = switch selectedRating {
                    case "All": true
                    case "Outstanding": report.rating.hasPrefix("Outstanding")
                    case "Good": report.rating.hasPrefix("Good")
                    case "Requires Improvement": report.rating.hasPrefix("Requires Improvement")
                    case "Inadequate": report.rating.hasPrefix("Inadequate")
                    case "Met": report.rating.hasPrefix("Outstanding") || report.rating.hasPrefix("Good") || report.rating == "Met"
                    case "Not Met": report.rating.hasPrefix("Requires Improvement") || report.rating.hasPrefix("Inadequate") || report.rating == "Not Met"
                    default: false
                }
                
                let matchesLocation = selectedLocation == nil || report.location == selectedLocation
                
                return matchesRating && matchesLocation
            }
            
            let matchingReportCount = matchingReports.count
            if matchingReportCount == 0 { return nil } // Filter out themes with no matching reports
            
            // Create updated correlation with new percentage based on matching reports
            var updatedCorrelation = correlation
            updatedCorrelation.percentage = totalFilteredReports > 0 ? (Double(matchingReportCount) / Double(totalFilteredReports)) * 100 : 0
            return updatedCorrelation
        }
        
        return filtered.sorted { $0.percentage > $1.percentage }
    }
    
    var uniqueLocations: [String] {
        Array(analytics.locations).sorted()
    }
    
    let ratingValues: [RatingValue] = [.outstanding, .good, .met, .requiresImprovement, .inadequate, .notmet]
    let effectivenessGrades = ["Outstanding (Met)", "Good (Met)", "Requires Improvement (Not Met)", "Inadequate (Not Met)"]
    
    var body: some View {
        VStack(spacing: 0) {
            CustomHeaderVIew(title: "Theme Analytics")
            
            ScrollView {
                VStack(spacing: 20) {
                    Spacer()
                        .frame(height: 20)
                        
                    // Header Stats
                    HStack(spacing: 20) {
                        StatCard(
                            title: "Average Themes",
                            value: String(format: "%.1f", analytics.averageThemesPerReport),
                            subtitle: "per report",
                            icon: "chart.bar.fill",
                            color: .color2,
                            infoAction: { showingAverageInfo.toggle() }
                        )
                        .alert(isPresented: $showingAverageInfo) {
                            Alert(
                                title: Text("Average Themes Per Report"),
                                message: Text("This shows the typical number of themes identified in each report by this inspector. A higher number may indicate more detailed analysis."),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                        
                        StatCard(
                            title: "Total Themes",
                            value: "\(analytics.frequentThemes.count)",
                            subtitle: "unique themes",
                            icon: "tag.fill",
                            color: .color7,
                            infoAction: { showingThemesInfo.toggle() }
                        )
                        .alert(isPresented: $showingThemesInfo) {
                            Alert(
                                title: Text("Total Unique Themes"),
                                message: Text("The total number of different themes this inspector has used across all their reports, showing their range of expertise."),
                                dismissButton: .default(Text("OK"))
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    CustomCardView("Top 5 Themes") {
                        LazyVStack(spacing: 12) {
                            ForEach(analytics.frequentThemes.prefix(5)) { theme in
                                HStack {
                                    Text(theme.theme)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(theme.count) reports")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Theme Correlations
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Theme Correlations")
                                    .font(.headline)
                                
                                Button(action: { showingCorrelationsInfo.toggle() }) {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.secondary)
                                }
                                .alert(isPresented: $showingCorrelationsInfo) {
                                    Alert(
                                        title: Text("Theme Correlations"),
                                        message: Text("Shows how often specific themes are associated with particular outcomes in the inspector's reports. This helps identify patterns in their assessments."),
                                        dismissButton: .default(Text("OK"))
                                    )
                                }
                                Spacer()
                            }
                            
                            // Filters row
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    Menu {
                                        Picker("Range", selection: $selectedPercentageRange) {
                                            ForEach(PercentageRange.allCases, id: \.self) { range in
                                                Text(range.rawValue).tag(range)
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "line.3.horizontal.decrease.circle")
                                            Text(selectedPercentageRange.rawValue)
                                        }
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.secondary.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                    
                                    Menu {
                                        ForEach(ratingOptions, id: \.self) { rating in
                                            Button(action: {
                                                selectedRating = rating
                                            }) {
                                                HStack {
                                                    Text(rating)
                                                    if rating == selectedRating {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(selectedRating)
                                                .foregroundColor(.primary)
                                            Image(systemName: "chevron.up.chevron.down")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color(UIColor.tertiarySystemFill))
                                        .cornerRadius(8)
                                    }
                                    
                                    Menu {
                                        Button("Clear", action: { selectedLocation = nil })
                                        ForEach(uniqueLocations, id: \.self) { location in
                                            Button(action: { 
                                                selectedLocation = location
                                                print("Selected location: \(location)")
                                            }) {
                                                HStack {
                                                    Text(location)
                                                    if selectedLocation == location {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "mappin.circle")
                                            Text(selectedLocation ?? "Location")
                                        }
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.secondary.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                                .padding(.horizontal, 1)
                            }
                        }
                        
                        if filteredCorrelations.isEmpty {
                            EmptyStateView(
                                icon: "magnifyingglass",
                                message: "No correlations found in this range"
                            )
                        } else {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(filteredCorrelations) { correlation in
                                    CorrelationCard(correlation: correlation)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                Spacer()
                    .frame(height: 20)
            }
            .scrollIndicators(.hidden)
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let infoAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: infoAction) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                }
            }
            .font(.subheadline)
            
            Text(value)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .cardBackground()
        .cornerRadius(12)
    }
}

struct CorrelationCard: View {
    let correlation: ThemeAnalyzer.ThemeCorrelation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text(correlation.theme)
                    .font(.headline)
                    .fontWeight(.regular)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .padding(.bottom)
                
     
                
            
                
             
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(correlation.percentage))")
                        .font(.title2)
                        .fontWeight(.regular)
                    Text("%")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: correlation.percentage, total: 100)
                .tint(.color2)
        }
        .padding()
        .frame(height: 200)
        .cardBackground()
        .cornerRadius(12)
    }
}

struct EmptyStateView: View {
    let icon: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundColor(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .cardBackground()
        .cornerRadius(12)
    }
}
