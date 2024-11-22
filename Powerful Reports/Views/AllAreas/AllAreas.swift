//
//  AllAreas.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 19/11/2024.
//

import SwiftUI

struct AreaProfile: Identifiable {
    let id = UUID()
    let name: String
    let totalInspections: Int
    let inspectors: [String: Int]
    let grades: [String: Int]
    let provisionTypes: [String: Int]
    let themes: [(topic: String, frequency: Int)]  // Added themes
}

struct AreaInformation: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
}

struct AllAreas: View {
    let reports: [Report]
    
    @Environment(\.presentationMode) private var presentationMode
    
    @State private var animateGradient: Bool = false
    
    private let startColor: Color = .color2
    private let endColor: Color = .color1
    
    private func getAreaProfile(name: String) -> AreaProfile {
        let areaReports = reports.filter { $0.localAuthority == name }
        
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
    
    private var groupedAreaData: [String: [AreaInformation]] {
        let areaCounts = Dictionary(grouping: reports) { $0.localAuthority }
            .mapValues { $0.count }
            .filter { !$0.key.isEmpty }
        
        let areaData = areaCounts.sorted { $0.value > $1.value }
            .map { AreaInformation(name: $0.key, count: $0.value) }
        
        return Dictionary(grouping: areaData) {
            String($0.name.prefix(1)).uppercased()
        }
    }
    
    var body: some View {
        
        
        
        
        
        VStack(alignment: .leading, spacing: 8) {
            
            CustomHeaderVIew(title: "All Areas", showBackButton: false)

            
            
            ScrollView {
                LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                    ForEach(Array(groupedAreaData.keys.sorted()), id: \.self) { letter in
                        Section {
                            ForEach(groupedAreaData[letter] ?? []) { item in
                                NavigationLink(destination: AreaView(area: getAreaProfile(name: item.name), reports: reports)) {
                                    HStack(alignment: .center) {
                                        Text(item.name)
                                            .font(.callout)
                                            .foregroundStyle(.color4)
                                        Spacer()
                                        Text("\(item.count)")
                                            .font(.subheadline)
                                        
                                    }
                                    .padding()
                                    .background(Color.color1.opacity(0.4))
                                    .cornerRadius(10)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        } header: {
                            ZStack {
                                Rectangle()
                                    .fill(Color.white)
                                    .ignoresSafeArea()
                                
                                Text(letter)
                                    .font(.title3)
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundStyle(.color4)
                            }
                            
                        }                        }
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
            .padding(.bottom)
            .background(.clear)
            .navigationBarHidden(true)
            
        }
        .ignoresSafeArea()
        
    }
    
    
    
}




