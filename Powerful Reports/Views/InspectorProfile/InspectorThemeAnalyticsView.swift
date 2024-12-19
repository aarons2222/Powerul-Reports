import SwiftUI
import Charts

struct InspectorThemeAnalyticsView: View {
    @StateObject private var viewModel: InspectorThemeAnalyticsViewModel
    let analytics: ThemeAnalyzer.InspectorThemeAnalytics
    let inspectorName: String
    @State private var showingAverageInfo = false
    @State private var showingCorrelationsInfo = false
    @State private var showingThemesInfo = false
    @State private var selectedPercentageRange = PercentageRange.all
    @State private var selectedRating: String = "All"
    @State private var selectedLocation: String? = nil
    @State private var showMetOnly = false
    @State private var showCorrelationInfo = false
    
    init(analytics: ThemeAnalyzer.InspectorThemeAnalytics, inspectorName: String) {
        self.analytics = analytics
        self.inspectorName = inspectorName
        _viewModel = StateObject(wrappedValue: InspectorThemeAnalyticsViewModel(analytics: analytics))
        
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
        let result = viewModel.filteredCorrelations(
            percentageRange: selectedPercentageRange,
            rating: selectedRating,
            location: selectedLocation,
            showMetOnly: showMetOnly
        )
        return result.correlations
    }
    
    var filteredThemes: [(theme: String, count: Int)] {
        let result = viewModel.filteredCorrelations(
            percentageRange: selectedPercentageRange,
            rating: selectedRating,
            location: selectedLocation,
            showMetOnly: showMetOnly
        )
        return result.themes
    }
    
    var uniqueLocations: [String] {
        Array(viewModel.uniqueLocations).sorted()
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
                            InfoAlert(title: "Average Themes Per Report", message: "his shows the typical number of themes identified in each report by this inspector. A higher number may indicate more detailed analysis.", show: $showingAverageInfo)
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
                            InfoAlert(title: "Total Unique Themes", message: "The total number of different themes this inspector has identified across all their reports.", show: $showingThemesInfo)
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
                                    InfoAlert(title: "Theme Correlations", message: "Shows how often specific themes are associated with particular outcomes in the inspector's reports. This helps identify patterns in their assessments.", show: $showCorrelationInfo)
                                }
                                
                                
                                Spacer()
                            }
                            
                            // Filters row
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    Menu {
                                        Picker("Range", selection: $selectedPercentageRange) {
                                            ForEach(PercentageRange.allCases, id: \.self) { range in
                                                Text(range.displayName).tag(range)
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: "line.3.horizontal.decrease.circle")
                                                .foregroundStyle(.color2)
                                            Text(selectedPercentageRange.displayName)
                                                .foregroundStyle(.color4)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(.color0.opacity(0.2)))
                                    }
                                    
                                    Menu {
                                        Button("All Grades", action: { selectedRating = "All" })
                                        ForEach(viewModel.availableRatings(forLocation: selectedLocation).filter { $0 != "All" }, id: \.self) { rating in
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
                                    
                                    if !viewModel.uniqueLocations.isEmpty {
                                        Menu {
                                            Button("All Locations", action: { selectedLocation = nil })
                                            ForEach(Array(viewModel.availableLocations(forRating: selectedRating)).sorted(), id: \.self) { location in
                                                Button(action: { 
                                                    selectedLocation = location
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
                                                    .foregroundStyle(.color2)
                                                Text(selectedLocation ?? "Location")
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
                                message: "No correlations found in this range"
                            )
                        } else {
                            VStack(spacing: 16){
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
                VStack{
                    Button(action: infoAction) {
                        Image(systemName: "info.circle")
                            .font(.title2)
                            .foregroundColor(.color1)
                    }
                    Spacer()
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
        
        
     
            VStack(alignment: .leading, spacing: 10) {
                Text(correlation.theme)
                    .font(.headline)
                    .fontWeight(.regular)
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(Int(correlation.percentage))")
                        .font(.subheadline)
                        .fontWeight(.regular)
                        .foregroundColor(.gray)
                    
                    Text("%")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        Spacer()
                }
                
                ProgressView(value: correlation.percentage, total: 100)
                    .tint(.color2)
            } .padding()
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



struct InfoAlert: View {
    var title: String
    var message: String
    @Binding var show: Bool
   
    var body: some View {
        
        
        
        
        VStack(spacing: 20) {
           
            
            Text(title)
                .font(.title3)
                .fontWeight(.regular)
              
            
            
            Text(message)
                .font(.body)
                .fontWeight(.regular)
            
        
            
            HStack(spacing: 10) {
                Button {
                    show = false
                } label: {
                    Text("Dismiss")
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 25)
                        .background {
                          Capsule()
                                .fill(.color1.gradient)
                        }
                }

            }
    
        }
        .frame(width: 250)
        .padding()
        .cardBackground()
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.white)
             
        }
       
        
        
    }
}
