import SwiftUI
import Charts

struct InspectorThemeAnalyticsView: View {
    let analytics: ThemeAnalyzer.InspectorThemeAnalytics
    let inspectorName: String
    @State private var showingAverageInfo = false
    @State private var showingCorrelationsInfo = false
    @State private var showingThemesInfo = false
    @State private var selectedPercentageRange = PercentageRange.all
    
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
    
    var filteredCorrelations: [ThemeAnalyzer.ThemeCorrelation] {
        guard let range = selectedPercentageRange.range else {
            return analytics.themeOutcomeCorrelations
        }
        return analytics.themeOutcomeCorrelations.filter { range.contains($0.percentage) }
    }
    
    var body: some View {
        
        VStack(spacing: 0) {
        
        CustomHeaderVIew(title: "Theme Analytics")
        
        ScrollView {
            
            Spacer()
                .frame(height: 20)
            
            VStack(spacing: 20) {
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
                    .popover(isPresented: $showingAverageInfo) {
                        InfoPopover(
                            title: "Average Themes Per Report",
                            description: "This shows the typical number of themes identified in each report by this inspector. A higher number may indicate more detailed analysis."
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
                    .popover(isPresented: $showingThemesInfo) {
                        InfoPopover(
                            title: "Total Unique Themes",
                            description: "The total number of different themes this inspector has used across all their reports, showing their range of expertise."
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
                    HStack {
                        Text("Theme Correlations")
                            .font(.headline)
                        
                        Button(action: { showingCorrelationsInfo.toggle() }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                        }
                        .popover(isPresented: $showingCorrelationsInfo) {
                            InfoPopover(
                                title: "Theme Correlations",
                                description: "Shows how often specific themes are associated with particular outcomes in the inspector's reports. This helps identify patterns in their assessments."
                            )
                        }
                        
                        Spacer()
                        
                        Menu {
                            Picker("Range", selection: $selectedPercentageRange) {
                                ForEach(PercentageRange.allCases, id: \.self) { range in
                                    Text(range.rawValue).tag(range)
                                }
                            }
                        } label: {
                            Label(selectedPercentageRange.rawValue, systemImage: "line.3.horizontal.decrease.circle")
                                .foregroundColor(.primary)
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
         
        }
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
            Text(correlation.theme)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(correlation.outcome)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(correlation.percentage))")
                        .font(.system(size: 28, weight: .bold))
                    Text("%")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            
            ProgressView(value: correlation.percentage, total: 100)
                .tint(.color2)
        }
        .padding()
        .frame(height: 180)
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

struct InfoPopover: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 300)
    }
}
