//
//  ContentView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 17/11/2024.
//

import SwiftUI

import Charts

struct DashboardItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let color: Color
}




struct OutcomeData: Identifiable {
    let id = UUID()
    let outcome: String
    let count: Int
    let color: Color
}



struct HomeView: View {
    
    @Namespace var hero
    @StateObject private var viewModel = InspectionReportsViewModel()
    
    
    @AppStorage("selectedTimeFilter") private var selectedTimeFilter: TimeFilter = .last30Days

    
    enum TimeFilter: String, Codable, CaseIterable {
        case last30Days = "30days"
        case last3Months = "3months"
        case last6Months = "6months"
        case last12Months = "12months"
        
        var title: String {
            switch self {
            case .last30Days: "30 Days"
            case .last3Months: "3 Months"
            case .last6Months: "6 Months"
            case .last12Months: "12 Months"
            }
        }
        
        var date: Date {
            let calendar = Calendar.current
            let now = Date()
            switch self {
            case .last30Days:
                return calendar.date(byAdding: .day, value: -30, to: now)!
            case .last3Months:
                return calendar.date(byAdding: .month, value: -3, to: now)!
            case .last6Months:
                return calendar.date(byAdding: .month, value: -6, to: now)!
            case .last12Months:
                return calendar.date(byAdding: .month, value: -12, to: now)!
            }
        }
    }
    
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
                .blue
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
            
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
          
                
                // Use filteredReports instead of viewModel.reports for all your cards
                HStack {
                    TotalReportsCard(
                        title: "Reports",
                        value: "\(filteredReports.count)",
                        icon: "append.page.rtl",
                        color: .green
                    )
                    
                    TotalReportsCard(
                        title: "Reports",
                        value: "\(filteredReports.count)",
                        icon: "append.page.rtl",
                        color: .green
                    )
                }
                
                
                
                
       
                    NavigationLink {
                        MostInspections(reports: viewModel.reports)
                            .toolbarRole(.editor)
                            .navigationTransition(.zoom(sourceID: filteredReports.first?.id, in: hero))
                        
                        
                    } label: {
                        TopInspectorsCard(reports: filteredReports)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .matchedTransitionSource(id: filteredReports.first?.id, in: hero)
               
                
                
                
                
                
                
                
                
                TopAreasCard(reports: filteredReports)
                OutcomesChartView(reports: filteredReports)
                ThemeRankingCard(themes: topThemes)
                ProvisionTypeCard(data: provisionTypeDistribution)
                
                
            }
            .padding()
        }
        .scrollIndicators(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Home")
        .toolbar{
            
            
       
            
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Time Filter", selection: $selectedTimeFilter) {
                        Text("This Month").tag(TimeFilter.last30Days)
                        Text("Last 3 Months").tag(TimeFilter.last3Months)
                        Text("Last 12 Months").tag(TimeFilter.last6Months)
                        Text("Last 12 Months").tag(TimeFilter.last12Months)
                    }
                   
                } label: {
                    Label("Time Filter", systemImage: "calendar")
                }
            }
            
            
        }
    }
}
  }


struct TotalReportsCard: View {
    var title: String
    var value: String
    var icon: String
    var color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(value)
                .font(.title)
                .bold()
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(height: 160)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}



#Preview {
    HomeView()
}





