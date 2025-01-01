import SwiftUI
import Charts

struct AuthorityThemeAnalyticsView: View {
    @StateObject private var viewModel: AuthorityThemeAnalyticsViewModel
    let analytics: ThemeAnalyzer.AuthorityThemeAnalytics
    let authorityName: String
    @State private var showingAverageInfo = false
    @State private var showingCorrelationsInfo = false
    @State private var showingThemesInfo = false
    @State private var selectedPercentageRange = PercentageRange.all
    @State private var selectedRating: String = "All"
    @State private var selectedInspector: String? = nil
    @State private var showMetOnly = false
    @State private var showCorrelationInfo = false
    
    init(analytics: ThemeAnalyzer.AuthorityThemeAnalytics, authorityName: String) {
        self.analytics = analytics
        self.authorityName = authorityName
        _viewModel = StateObject(wrappedValue: AuthorityThemeAnalyticsViewModel(analytics: analytics))
        
        // Print all unique themes first
        let allThemes = Set(analytics.frequentThemes.map { $0.theme }).sorted()
        print("\nAll Unique Themes List:")
        for (index, theme) in allThemes.enumerated() {
            print("\(theme) [\(index + 1)]")
        }
        print("Total unique themes: \(allThemes.count)\n")
        
        // Print themes by correlation
        print("\nThemes by Correlation:")
        for correlation in analytics.themeOutcomeCorrelations {
            print("\nTheme Group:")
            print(correlation.theme)
            print("Rating: \(correlation.outcome)")
            print("Percentage: \(Int(correlation.percentage))%")
            print("Number of reports: \(correlation.ratingReports.count)")
            print("---")
        }
    }
    
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
        
        var displayName: String {
            switch self {
            case .all: return "All"
            case .seventyFiveToHundred: return "75-100%"
            case .fiftyToSeventyFive: return "50-75%"
            case .twentyFiveToFifty: return "25-50%"
            case .zeroToTwentyFive: return "0-25%"
            }
        }
    }
    
    var filteredCorrelations: [ThemeAnalyzer.ThemeCorrelation] {
        let result = viewModel.filteredCorrelations(
            percentageRange: selectedPercentageRange,
            rating: selectedRating,
            location: selectedInspector,
            showMetOnly: showMetOnly
        )
        return result.correlations
    }
    
    var filteredThemes: [(theme: String, count: Int)] {
        let result = viewModel.filteredCorrelations(
            percentageRange: selectedPercentageRange,
            rating: selectedRating,
            location: selectedInspector,
            showMetOnly: showMetOnly
        )
        return result.themes
    }
    
    var uniqueInspectors: [String] {
        Array(viewModel.uniqueInspectors).sorted()
    }
    
    let ratingValues: [RatingValue] = [.outstanding, .good, .met, .requiresImprovement, .inadequate, .notmet]
    let effectivenessGrades = ["Outstanding", "Good ", "Requires Improvement", "Inadequate (Not Met)"]
    
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
                        .popView(isPresented: $showingAverageInfo) {
                            showingAverageInfo = false
                        } content: {
                            InfoAlert(title: "Average Themes Per Report", message: "This shows the typical number of themes identified in each report for this authority. A higher number may indicate more detailed analysis.", show: $showingAverageInfo)
                        }
                        
                        StatCard(
                            title: "Unique Themes",
                            value: "\(analytics.frequentThemes.count)",
                            subtitle: "unique themes",
                            icon: "tag.fill",
                            color: .color7,
                            infoAction: { showingThemesInfo.toggle() }
                        )
                        .popView(isPresented: $showingThemesInfo) {
                            showingThemesInfo = false
                        } content: {
                            InfoAlert(title: "Total Unique Themes", message: "The total number of different themes identified across all reports for this authority.", show: $showingThemesInfo)
                        }
                    }
                    .padding(.horizontal)
                    
                    CustomCardView("Top 5 Themes") {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredThemes.prefix(5), id: \.theme) { theme in
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
                                Button(action: {
                                    showCorrelationInfo.toggle()
                                }) {
                                    Image(systemName: "info.circle")
                                        .font(.title2)
                                        .foregroundColor(.color4)
                                }
                                .popView(isPresented: $showCorrelationInfo) {
                                    showCorrelationInfo = false
                                } content: {
                                    InfoAlert(title: "Theme Correlations", message: "Shows how often specific themes are associated with particular outcomes in the authority's reports. This helps identify patterns in assessments.", show: $showCorrelationInfo)
                                }
                                Spacer()
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    Menu {
                                        Button("All", action: { selectedPercentageRange = .all })
                                        ForEach(PercentageRange.allCases.filter({ $0 != .all }), id: \.self) { range in
                                            Button(action: {
                                                selectedPercentageRange = range
                                            }) {
                                                HStack {
                                                    Text(range.displayName)
                                                    if range == selectedPercentageRange {
                                                        Image(systemName: "checkmark")
                                                    }
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "line.3.horizontal.decrease.circle")
                                                .foregroundStyle(.color2)
                                            Text(selectedPercentageRange == .all ? "All" : selectedPercentageRange.displayName)
                                                .foregroundStyle(.color4)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(.color0.opacity(0.2)))
                                    }
                                    
                                    Menu {
                                        Button("All Grades", action: { selectedRating = "All" })
                                        ForEach(viewModel.availableRatings.filter({ $0 != "All" }), id: \.self) { rating in
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
                                            Image(systemName: "star.circle")
                                                .foregroundStyle(.color2)
                                            Text(selectedRating == "All" ? "Grade" : selectedRating)
                                                .foregroundStyle(.color4)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(.color0.opacity(0.2)))
                                    }
                                    
                                    if !uniqueInspectors.isEmpty {
                                        Menu {
                                            Button("All Inspectors", action: { selectedInspector = nil })
                                            ForEach(uniqueInspectors.sorted(), id: \.self) { inspector in
                                                Button(action: {
                                                    selectedInspector = inspector
                                                }) {
                                                    HStack {
                                                        Text(inspector)
                                                        if inspector == selectedInspector {
                                                            Image(systemName: "checkmark")
                                                        }
                                                    }
                                                }
                                            }
                                        } label: {
                                            HStack {
                                                Image(systemName: "person.circle")
                                                    .foregroundStyle(.color2)
                                                Text(selectedInspector ?? "Inspectors")
                                                    .foregroundStyle(.color4)
                                            }
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Capsule().fill(.color0.opacity(0.2)))
                                        }
                                    }
                                }
                                .padding(.horizontal, 1)
                            }
                        }
                        
                        if filteredCorrelations.isEmpty {
                            EmptyStateView(
                                icon: "magnifyingglass",
                                message: "Try adjusting your filters to see more results"
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 16) {
                                ForEach(filteredCorrelations, id: \.theme) { correlation in
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
