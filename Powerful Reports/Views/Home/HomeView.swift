//
//  ContentView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 17/11/2024.
//

import SwiftUI
import Charts
import StoreKit


struct HomeView: View {
    
    @State private var showScriptionView: Bool = false
    @State private var status: EntitlementTaskState<SubscriptionStatus> = .loading
    @State private var showPaywall = false
    
    @Environment(\.subscriptionIDs) private var subscriptionIDs
    
    

    @Namespace var hero
    @StateObject private var viewModel = InspectionReportsViewModel()
    @Environment(\.colorScheme) private var scheme
    @Environment(SubscriptionStatusModel.self) private var subscriptionStatusModel
    @State var showSettings = false

    @State private var path = [NavigationPath]()
    @State private var isInitialized = false
    
        @Environment(\.horizontalSizeClass) var sizeClass
    var gridColumns: [GridItem] {
        if viewModel.reportsCount == 1 {
            return [GridItem(.flexible(), spacing: 16)]
        } else {
            let columns = sizeClass == .regular ? 3 : 2
            return Array(repeating: GridItem(.flexible(), spacing: 16), count: columns)
        }
    }
    
    
    private var provisionTypeDistribution: [OutcomeData] {

        let types = viewModel.filteredReports.map { $0.typeOfProvision }
        let counts = Dictionary(grouping: types) { $0 }
            .mapValues { $0.count }

        
        return counts.map { type, count in
            let displayType = type.isEmpty ? "Not Specified" : type
            
            let color: Color = if type.contains("Childminder") {
                .color1
            } else if type.contains("non-") {
                .color6
            } else if type.contains("childcare on domestic") {
                .color5
            } else {
                .color7
            }
            
            return OutcomeData(
                outcome: displayType,
                count: count,
                color: color
            )
        }.sorted { $0.count > $1.count }
    }
    
    
    
//    
//    private func getTheThemes(amount: Int?) -> [(String, Int)] {
//        let allThemes = viewModel.filteredReports.flatMap { $0.themes }
//        var themeCounts: [String: Int] = [:]
//        
//        allThemes.forEach { theme in
//            themeCounts[theme.topic, default: 0] += theme.frequency
//        }
//        
//        let sorted = themeCounts.sorted { $0.value > $1.value }
//        return amount == nil ? sorted : sorted.prefix(amount!).map { ($0.key, $0.value) }
//    }

    
    func getTheThemes() -> [(String, Int)] {
        let allThemes = viewModel.filteredReports.flatMap { $0.themes }
        var themeCounts: [String: Int] = [:]
        
        // Count each appearance of a theme
        allThemes.forEach { theme in
            themeCounts[theme.topic, default: 0] += 1
        }
        
        // Sort by frequency (highest to lowest) and convert to array of tuples
        let sorted = themeCounts.sorted { $0.value > $1.value }
            .map { ($0.key, $0.value) }
        
        return sorted
    }

    func getTopThemeFrequencies() -> [(String, Int)] {
        return getTheThemes().prefix(5).map { ($0.0, $0.1) }
    }
    
    var body: some View {
        
        NavigationStack(path: $path) {

            
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 15, content: {
                    
                    HStack(alignment: .center){
                        Text("Overview")
                            .font(.largeTitle)
                            .frame(height: 45)
                            .padding(.horizontal, 15)
                            .foregroundStyle(.color4)
                        
                        
                        Spacer()
                        
                        
                        Button{
                            self.showSettings = true
                        }label: {
                            Image(systemName: "gear")
                                .font(.title)
                                .foregroundStyle(.color1)
                                .padding(.horizontal)
                                .padding(.bottom)
                        }
                      
                        
                    }
                    
                    GeometryReader {
                        let rect = $0.frame(in: .scrollView)
                        let minY = rect.minY.rounded()
                        
                        /// Card View
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 0) {
                                
                                
                                
                                ZStack {
                                    if minY == 75.0 {
                                        /// Not Scrolled
                                        /// Showing All Cards
                                        CardView(reportNumber: viewModel.reportsCount)
                                    } else {
                                        /// Scrolled
                                        /// Showing Only Selected Card
                                        CardView(reportNumber: viewModel.reportsCount)
                                        
                                    }
                                }
                                .containerRelativeFrame(.horizontal)
                                
                            }
                            .scrollTargetLayout()
                        }
                        .scrollTargetBehavior(.paging)
                        .scrollClipDisabled()
                        .scrollIndicators(.hidden)
                        .scrollDisabled(minY != 75.0)
                    }
                    .frame(height: 125)
                })
                
    
                
                
                LazyVStack(spacing: 15) {
                    
           
                    
                    if subscriptionStatusModel.subscriptionStatus == .notSubscribed {
                        VStack(spacing: 0) {
                      
                            
                            Button {
                                self.showPaywall = true
                            } label: {
                                HStack(alignment: .center, spacing: 16) {
                                    // Left side with icon and text
                                    HStack(spacing: 12) {
                                        Image(systemName: "sparkles")
                                            .font(.title)
                                            .foregroundColor(.color2)
                                            .symbolEffect(.bounce.up.byLayer, options: .repeating)
                                            .symbolEffect(.pulse.byLayer, options: .repeating)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Unlock Full Access")
                                                .font(.headline)
                                                .fontWeight(.regular)
                                                .foregroundColor(.primary)
                                            
                                            Text("You're viewing demo data")
                                                .font(.body)
                                                .fontWeight(.regular)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                               
                                    Text("Upgrade")
                                        .font(.headline)
                                        .fontWeight(.regular)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.color1)
                                        .clipShape(Capsule())
                                }
                                .padding()
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .cardBackground()
                        .padding(.horizontal)
                    }
                    
                    SegmentedControl(
                        tabs: TimeFilter.allCases,
                        activeTab: $viewModel.selectedTimeFilter,
                        height: 35,
                        extraText: nil,
                        font: .callout,
                        activeTint: .color2,
                        inActiveTint: .color4.opacity(0.8)
                    ) { size in
                        RoundedRectangle(cornerRadius: 0)
                            .fill(.color2)
                            .frame(height: 3)
                            .padding(.horizontal, 10)
                            .offset(y: 2)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                    .padding(.horizontal)
                    .onChange(of: viewModel.selectedTimeFilter) {
                        print("Filter changed to: \(viewModel.selectedTimeFilter)")  // Debug print
                                                Task {
                                                    await viewModel.filterReports(timeFilter: viewModel.selectedTimeFilter)
                                                }
                                            }
                   
                    
                    
                    ScrollView {
                        
                        
                        
                     
                                       Button {
                                           path.append(.annualStats)
                                       } label: {
                                           OutcomesChartView(reports: viewModel.filteredReports, viewModel: viewModel)
                                               .padding(.bottom)
                                       }
                                       .buttonStyle(PlainButtonStyle())
                                       .matchedTransitionSource(id: viewModel.filteredReports.first?.outcome, in: hero)
                                       
                        
                        
                        
                        /// all themes
                                       Button {
                                           path.append(.themes)
                                       } label: {
                                           ThemeRankingCard(themes: getTopThemeFrequencies())
                                               .padding(.bottom)
                                       }
                                       .buttonStyle(PlainButtonStyle())
                                       .matchedTransitionSource(id: viewModel.filteredReports.first?.themes, in: hero)
                        
                        
                        
                        
                        
                        /// instpectos
                                       Button {
                                           path.append(.inspectors)
                                       } label: {
                                           TopInspectorsCard(reports: viewModel.filteredReports)
                                               .padding(.bottom)
                                       }
                                       .buttonStyle(PlainButtonStyle())
                                       .matchedTransitionSource(id: viewModel.filteredReports.first?.inspector, in: hero)
                                       
                        
                        
                        
                                       Button {
                                           path.append(.authorities)
                                       } label: {
                                           
                                           TopAuthoritiesCard(reports: viewModel.filteredReports)
                                               .padding(.bottom)
                                       }
                                       .buttonStyle(PlainButtonStyle())
                                       .matchedTransitionSource(id: viewModel.filteredReports.first?.localAuthority, in: hero)
                                       
                        
                        
                        
                                        Button {
                                            path.append(.provisionInformation)
                                        } label: {
                                            ProvisionTypeCard(data: provisionTypeDistribution, viewModel: viewModel)
                                                .padding(.bottom)
                                        }
                                       
                        
                        
                        
                                        GlobalButton(title: "All Reports", action: {
                                            Task{
                                                path.append(.allReports)
                                            }
                                        })
                                        .buttonStyle(PlainButtonStyle())
                                        .matchedTransitionSource(id: viewModel.filteredReports.first?.overallRating, in: hero)
                        
                                     
                                   }
                                   .padding()
                                   .scrollIndicators(.hidden)
                    
                }
                .padding(.vertical)
                .mask {
                    Rectangle()
                        .visualEffect { content, proxy in
                            content
                                .offset(y: backgroundLimitOffset(proxy))
                        }
                }
                .background {
                    
                    GeometryReader {
                        let rect = $0.frame(in: .scrollView)
                        let minY = min(rect.minY - 125, 0)
                        let progress = max(min(-minY / 25, 1), 0)
                        
                        RoundedRectangle(cornerRadius: 30 * progress, style: .continuous)
                            .fill(scheme == .dark ? .black : .white)
                            .visualEffect { content, proxy in
                                    content
                                        .offset(y: backgroundLimitOffset(proxy))
                                
                            }
                    }
                }
            }
            .padding(.vertical, 15)
        }
            

        .scrollIndicators(.hidden)
        .scrollTargetBehavior(CustomScrollBehaviour())
            
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
                .environment(subscriptionStatusModel)
        }
        .sheet(isPresented: $showPaywall) {
            Paywall()
                .environment(subscriptionStatusModel)
        }
   
            
            
        .navigationDestination(for: NavigationPath.self) { destination in
                    switch destination {
                    case .annualStats:
                        AnnualStatsView(viewModel: viewModel)
                            .navigationTransition(.zoom(sourceID: viewModel.filteredReports.first?.outcome, in: hero))
                   
                        
                    case .inspectors:
                        AllInspectors(reports: viewModel.reports, path: $path)
                            .navigationTransition(.zoom(sourceID: viewModel.filteredReports.first?.inspector, in: hero))
                   
                    case .authorities:
                        AllAuthorities(reports: viewModel.reports, path: $path)
                            .navigationTransition(.zoom(sourceID: viewModel.filteredReports.first?.localAuthority, in: hero))
                    case .themes:
                        let themeData = viewModel.getThemeAnalysis()
                        ThemesView(themes: themeData)
                            .navigationTransition(.zoom(sourceID: viewModel.filteredReports.first?.themes.first, in: hero))
                        
                        
                    case .provisionInformation:
                        ProvisionInformation(reports: viewModel.reports)
                            .navigationTransition(.zoom(sourceID: viewModel.filteredReports.first?.previousInspection, in: hero))
                        
                    case .allReports:
                        AllReportsView(mainViewModel: viewModel, path: $path)
                            .navigationTransition(.zoom(sourceID: viewModel.filteredReports.first?.overallRating, in: hero))
                        
                        
                        
                        /// child views
                    case .inspectorProfile(let name):
                        InspectorProfileView(profile: getInspectorProfile(name: name), reports: viewModel.reports, path: $path)
                        
                    case .authorityProfile(let name):
                        AuthorityView(authority: getAuthorityProfile(name: name), reports: viewModel.reports, path: $path)
                    
                    
                    
                    case .reportView(let report):
                        ReportView(report: report)

                                       
                                  
                    case .moreReports(let reports, let name):
                        MoreReportsView(reports: reports, name: name, path: $path)
                    }
            
        
                }
            

     
    }
        
        .onChange(of: subscriptionStatusModel.subscriptionStatus){
            Task{
                if subscriptionStatusModel.subscriptionStatus == .notSubscribed {
                    viewModel.isPremium = false
                    print("here0")
                }else{
                    viewModel.isPremium = true
                    print("here1")
                }
            }
        }
        .task {
            guard !isInitialized else { return }
            isInitialized = true
            await viewModel.filterReports(timeFilter: viewModel.selectedTimeFilter)
            
            if subscriptionStatusModel.subscriptionStatus == .notSubscribed {
                viewModel.isPremium = false
                print("here2")
            }else{
                print("here3")
                viewModel.isPremium = true
            }
            
     


        }
      
        
                .subscriptionStatusTask(for: subscriptionIDs.group) { taskStatus in
                    self.status = await taskStatus.map { statuses in
                        await ProductSubscription.shared.status(
                            for: statuses,
                            ids: subscriptionIDs
                        )
                    }
                    switch self.status {
                    case .failure(let error):
                        subscriptionStatusModel.subscriptionStatus = .notSubscribed
                        print("Failed to check subscription status: \(error)")
                    case .success(let status):
                        subscriptionStatusModel.subscriptionStatus = status
                        print("Updated subscription status to: \(status)")
                    case .loading: break
                    @unknown default: break
                    }
                }
               
        
    }
    
    nonisolated func backgroundLimitOffset(_ proxy: GeometryProxy) -> CGFloat {
        let minY = proxy.frame(in: .scrollView).minY
        return minY < 100 ? -minY + 100 : 0
    }
    
    /// Card View
    @ViewBuilder
    func CardView(reportNumber: Int) -> some View {
        GeometryReader {
            let rect = $0.frame(in: .scrollView(axis: .vertical))
            let minY = rect.minY
            let topValue: CGFloat = 75.0
            
            let offset = min(minY - topValue, 0)
            let progress = max(min(-offset / topValue, 1), 0)
            let scale: CGFloat = 1 + progress
            
            let overlapProgress = max(min(-minY / 25, 1), 0) * 0.15
            
            ZStack {
                Rectangle()
                    .fill(.color1)
                    .overlay(alignment: .leading) {
                        Circle()
                            .fill(.color1)
                            .overlay {
                                Circle()
                                    .fill(.white.opacity(0.2))
                            }
                            .scaleEffect(2, anchor: .topLeading)
                            .offset(x: -50, y: -40)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                    .scaleEffect(scale, anchor: .init(x: 0.5, y: 1 - overlapProgress))
                
                VStack(alignment: .leading, spacing: 4, content: {
                    Spacer(minLength: 0)
                    
                    Text("\(reportNumber)")
                        .font(.largeTitle)
                        .fontWeight(.regular)
                    
                    Text("\(!viewModel.isPremium ? "Sample" : "Total")  Reports")
                        .font(.callout)
                    
                  
                })
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(15)
                .offset(y: progress * -25)
            }
            .offset(y: -offset)
            .offset(y: progress * -topValue)
        }
        .padding(.horizontal, 15)
    }
    
    struct ScaleButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
        }
    }
    
    private func getInspectorProfile(name: String) -> InspectorProfile {
        let inspectorReports = viewModel.reports.filter { $0.inspector == name }
        
        let authorities = Dictionary(grouping: inspectorReports) { $0.localAuthority }
            .mapValues { $0.count }
        
        var allGrades: [String: Int] = [:]
        
        inspectorReports.forEach { report in
            if let overallRating = report.ratings.first(where: { $0.category == RatingCategory.overallEffectiveness.rawValue }) {
                allGrades[overallRating.rating, default: 0] += 1
            } else {
                if !report.outcome.isEmpty {
                    allGrades[report.outcome, default: 0] += 1
                }
            }
        }
        
        return InspectorProfile(
            name: name,
            totalInspections: inspectorReports.count,
            authorities: authorities,
            grades: allGrades
        )
    }
    
    
    
    private func getAuthorityProfile(name: String) -> AuthorityProfile {
        let authorityReports = viewModel.reports.filter { $0.localAuthority == name }
        
        let inspectors = Dictionary(grouping: authorityReports) { $0.inspector }
            .mapValues { $0.count }
        
        var allGrades: [String: Int] = [:]
        
        // Count overall effectiveness ratings and outcomes
        authorityReports.forEach { report in
            if let overallRating = report.ratings.first(where: { $0.category == RatingCategory.overallEffectiveness.rawValue }) {
                allGrades[overallRating.rating, default: 0] += 1
            } else {
                if !report.outcome.isEmpty {
                    allGrades[report.outcome, default: 0] += 1
                }
            }
        }
        
        
        let provisionTypes = Dictionary(grouping: authorityReports) { $0.typeOfProvision }
            .mapValues { $0.count }
        
        // Calculate themes
        var themeCounts: [String: Int] = [:]
        authorityReports.forEach { report in
            report.themes.forEach { theme in
                themeCounts[theme.topic, default: 0] += theme.frequency
            }
        }
        let sortedThemes = themeCounts.map { (topic: $0.key, frequency: $0.value) }
            .sorted { $0.frequency > $1.frequency }
        
        return AuthorityProfile(
            name: name,
            totalInspections: authorityReports.count,
            inspectors: inspectors,
            grades: allGrades,
            provisionTypes: provisionTypes,
            themes: sortedThemes
        )
    }
}

struct CustomScrollBehaviour: ScrollTargetBehavior {
    func updateTarget(_ target: inout ScrollTarget, context: TargetContext) {
        if target.rect.minY < 75 {
            target.rect = .zero
        }
    }
}

#Preview {
    HomeView()
}



enum NavigationPath: Hashable {
    case annualStats
    case inspectors
    case inspectorProfile(String)
    case authorityProfile(String)
    case authorities
    case themes
    case provisionInformation
    case allReports
    case reportView(Report)
    case moreReports([Report], String)
}
