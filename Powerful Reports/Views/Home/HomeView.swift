//
//  ContentView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 17/11/2024.
//

import SwiftUI
import Charts



struct HomeView: View {

        @Namespace var hero
        @StateObject private var viewModel = InspectionReportsViewModel()
    
        @Environment(\.colorScheme) private var scheme
    
    
          @State var showSettings = false
    
    @AppStorage("selectedTimeFilter") private var selectedTimeFilter: TimeFilter = .last3Months

    
    
    @State private var path = [NavigationPath]()


    
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
//        // Add a debug print to see what's coming in
//        print("Filtered reports_count: \(viewModel.filteredReports.count)")
//        print("All reports_count: \(viewModel.reports.count)")
//        print("Unique types: \(Set(viewModel.filteredReports.map { $0.typeOfProvision }))")
        
        let types = viewModel.filteredReports.map { $0.typeOfProvision }
        let counts = Dictionary(grouping: types) { $0 }
            .mapValues { $0.count }
        
        // Add a debug print to see the counts
            //  print("Counts dictionary: \(counts)")
        
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
    
    
    
    
    private func getTheThemes(amount: Int?) -> [(String, Int)] {
        let allThemes = viewModel.filteredReports.flatMap { $0.themes }
        var themeCounts: [String: Int] = [:]
        
        allThemes.forEach { theme in
            themeCounts[theme.topic, default: 0] += theme.frequency
        }
        
        let sorted = themeCounts.sorted { $0.value > $1.value }
        return amount == nil ? sorted : sorted.prefix(amount!).map { ($0.key, $0.value) }
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
                                        CardView(reportNumber: viewModel.getTotalReportsCount())
                                    } else {
                                        /// Scrolled
                                        /// Showing Only Selected Card
                                        CardView(reportNumber: viewModel.getTotalReportsCount())
                                        
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

                    
                    SegmentedControl(
                        tabs: TimeFilter.allCases,
                        activeTab: $selectedTimeFilter,
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
                    .onChange(of: selectedTimeFilter) {
                                                print("Filter changed to: \(selectedTimeFilter)")  // Debug print
                                                Task {
                                                    await viewModel.filterReports(timeFilter: selectedTimeFilter)
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
                                           ThemeRankingCard(themes: getTheThemes(amount: 5))
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
                                       
                        
                        
                        /// all areas
                                       Button {
                                           path.append(.areas)
                                       } label: {
                                           TopAreasCard(reports: viewModel.filteredReports)
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
            
        .sheet(isPresented: $showSettings) {
                SettingsView(viewModel: viewModel)
                       .presentationDetents([.large])
               }
            
            
        .navigationDestination(for: NavigationPath.self) { destination in
                    switch destination {
                    case .annualStats:
                        AnnualStats(allReports: viewModel.reports)
                            .navigationTransition(.zoom(sourceID: viewModel.filteredReports.first?.outcome, in: hero))
                   
                        
                    case .inspectors:
                        AllInspectors(reports: viewModel.reports, path: $path)
                            .navigationTransition(.zoom(sourceID: viewModel.filteredReports.first?.inspector, in: hero))
                   
                    case .areas:
                        AllAreas(reports: viewModel.reports, path: $path)
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
                        
                    case .areaProfile(let name):
                        AreaView(area: getAreaProfile(name: name), reports: viewModel.reports, path: $path)
                    
                    
                    
                    case .reportView(let report):
                        ReportView(report: report)

                                       
                                  
                    case .moreReports(let reports, let name):
                        MoreReportsView(reports: reports, name: name, path: $path)
                    }
            
        
                }
            

     
    }
        .onAppear {
                    Task {
                        await viewModel.filterReports(timeFilter: selectedTimeFilter)
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
                    
                    Text("Total Reports")
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
    
    
    
    
    
    
    private func getInspectorProfile(name: String) -> InspectorProfile {
        let inspectorReports = viewModel.reports.filter { $0.inspector == name }
        
        let areas = Dictionary(grouping: inspectorReports) { $0.localAuthority }
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
            areas: areas,
            grades: allGrades
        )
    }
    
    
    
    private func getAreaProfile(name: String) -> AreaProfile {
        let areaReports = viewModel.reports.filter { $0.localAuthority == name }
        
        let inspectors = Dictionary(grouping: areaReports) { $0.inspector }
            .mapValues { $0.count }
        
        var allGrades: [String: Int] = [:]
        
        // Count overall effectiveness ratings and outcomes
        areaReports.forEach { report in
            if let overallRating = report.ratings.first(where: { $0.category == RatingCategory.overallEffectiveness.rawValue }) {
                allGrades[overallRating.rating, default: 0] += 1
            } else {
                if !report.outcome.isEmpty {
                    allGrades[report.outcome, default: 0] += 1
                }
            }
        }
        
        
        let provisionTypes = Dictionary(grouping: areaReports) { $0.typeOfProvision }
            .mapValues { $0.count }
        
        // Calculate themes
        var themeCounts: [String: Int] = [:]
        areaReports.forEach { report in
            report.themes.forEach { theme in
                themeCounts[theme.topic, default: 0] += theme.frequency
            }
        }
        let sortedThemes = themeCounts.map { (topic: $0.key, frequency: $0.value) }
            .sorted { $0.frequency > $1.frequency }
        
        return AreaProfile(
            name: name,
            totalInspections: areaReports.count,
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
    case areaProfile(String)
    case areas
    case themes
    case provisionInformation
    case allReports
    case reportView(Report)
    case moreReports([Report], String)
}
