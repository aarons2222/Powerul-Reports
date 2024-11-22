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
    
    
        @AppStorage("selectedTimeFilter") private var selectedTimeFilter: TimeFilter = .last30Days
    @Environment(\.colorScheme) private var scheme
    
    
    @State var showSettings = false
    
    
    
        var filteredReports: [Report] {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy"
    
            return viewModel.reports.filter { report in
                guard let reportDate = dateFormatter.date(from: report.date) else { return false }
                return reportDate >= selectedTimeFilter.date
            }
        }
    
    
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
            let types = viewModel.reports.map { $0.typeOfProvision }
            let counts = Dictionary(grouping: types) { $0 }
                .mapValues { $0.count }
    
            return counts.map { type, count in
    
    
    
    
    
                let displayType = type.isEmpty ? "Not Specified" : type
    
    
    
    
                let color: Color = if type.contains("Childminder") {
                    .color1
                } else if type.contains("childcare on non-domestic") {
                    .green
                }else if  type.contains("childcare on domestic") {
                    .yellow
                } else {
                    .purple
                }
    
                return OutcomeData(
                    outcome: displayType,
                    count: count,
                    color: color
                )
            }.sorted { $0.count > $1.count }
        }
    
        private var topThemes: [(String, Int)] {
            let allThemes = viewModel.reports.flatMap { $0.themes }
            var themeCounts: [String: Int] = [:]
    
            allThemes.forEach { theme in
                themeCounts[theme.topic.capitalized, default: 0] += theme.frequency
            }
    
            return themeCounts.sorted { $0.value > $1.value }
                .prefix(5)
                .map { ($0.key, $0.value) }
        }
    
    
    
        
    
    
    var body: some View {
        
        NavigationStack{
            
        ScrollView(.vertical) {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 15, content: {
                    
                    HStack(alignment: .center){
                        Text("Dashboard")
                            .font(.largeTitle.bold())
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
                    Menu {
                        Picker("Time Filter", selection: $selectedTimeFilter) {
                            Text("This Month").tag(TimeFilter.last30Days)
                            Text("Last 3 Months").tag(TimeFilter.last3Months)
                            Text("Last 6 Months").tag(TimeFilter.last6Months)
                            Text("Last 12 Months").tag(TimeFilter.last12Months)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Filter By")
                            Image(systemName: "chevron.down")
                        }
                        .font(.caption)
                        .foregroundStyle(.gray)
                      
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            
                            
                            OutcomesChartView(reports: filteredReports)
                            
                         
                            
                            
                            NavigationLink {
                                AllInspectors(reports: viewModel.reports)
                                    .navigationTransition(.zoom(sourceID: filteredReports.first?.typeOfProvision, in: hero))
                                
                                
                            } label: {
                                TopInspectorsCard(reports: filteredReports)
                                    .padding(5)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .matchedTransitionSource(id: filteredReports.first?.typeOfProvision, in: hero)
                            
                            
                            
                            
                            NavigationLink {
                                AllAreas(reports: viewModel.reports)
                                    .navigationTransition(.zoom(sourceID: filteredReports.first?.localAuthority, in: hero))
                                
                                
                            } label: {
                                TopAreasCard(reports: filteredReports)
                                    .padding(5)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .matchedTransitionSource(id: filteredReports.first?.localAuthority, in: hero)
                            
                            
                            
                       
                            ThemeRankingCard(themes: topThemes)
                            ProvisionTypeCard(data: provisionTypeDistribution)
                        }
                        .padding()
                    }
                    .scrollIndicators(.hidden)
                }
                .padding(15)
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
        .scrollTargetBehavior(CustomScrollBehaviour())
            
        .fullScreenCover(isPresented: $showSettings, content: SettingsView.init)

     
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
                        .font(.title.bold())
                    
                    Text("Total Reports")
                        .font(.callout)
                    
                  
                })
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(15)
                .offset(y: progress * -25)
            }
            .offset(y: -offset)
            /// Moving til Top Value
            .offset(y: progress * -topValue)
        }
        .padding(.horizontal, 15)
    }
    
}

/// Custom Scroll Target Behaviour
/// AKA scrollWillEndDragging in UIKit
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





//
//struct DashboardItem: Identifiable {
//    let id = UUID()
//    let title: String
//    let value: String
//    let icon: String
//    let color: Color
//}




struct OutcomeData: Identifiable {
    let id = UUID()
    let outcome: String
    let count: Int
    let color: Color
}

