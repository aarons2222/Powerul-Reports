//
//  MostInspections.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 19/11/2024.
//

import SwiftUI

struct InspectorProfile: Identifiable {
    let id = UUID()
    let name: String
    let totalInspections: Int
    let areas: [String: Int]
    let grades: [String: Int]
}
struct AllInspectors: View {
    
    @Binding var path: [NavigationPath]

    
    let reports: [Report]
    @State private var searchText = ""
    
    private func getInspectorProfile(name: String) -> InspectorProfile {
        let inspectorReports = reports.filter { $0.inspector == name }
        
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
    

    
    private var groupedInspectorData: [String: [InstpectorData]] {
        let inspectorCounts = Dictionary(grouping: reports) { $0.inspector }
            .mapValues { $0.count }
            .filter { !$0.key.isEmpty }
        
        let inspectorData = inspectorCounts.sorted { $0.value > $1.value }
            .map { InstpectorData(name: $0.key, count: $0.value) }
        
        return Dictionary(grouping: inspectorData) {
            String($0.name.prefix(1)).uppercased()
        }
    }
    
    private var filteredInspectorData: [String: [InstpectorData]] {
        if searchText.isEmpty {
            return groupedInspectorData
        }
        
        let filteredData = groupedInspectorData.flatMap { _, areas in
            areas.filter { area in
                area.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return Dictionary(grouping: filteredData) {
            String($0.name.prefix(1)).uppercased()
        }
    }
    
    
    init(reports: [Report], path: Binding<[NavigationPath]>) {
        self.reports = reports
        self._path = path
    }
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CustomHeaderVIew(title: "Inspectors")
            
            
            SearchBar(searchText: $searchText, placeHolder: "Search \(Set(reports.map { $0.inspector }).count) Inspectors...")
            
            if filteredInspectorData.isEmpty {
                HStack {
                    Spacer()
                    VStack {
                        Text("Inspector not found")
                            .font(.title)
                            .foregroundStyle(.color2)
                    }
                    Spacer()
                }
                .padding(.top, 30)
                Spacer()
            } else {
                ScrollView {
                   LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                       ForEach(Array(filteredInspectorData.keys.sorted()), id: \.self) { letter in
                           if let inspectors = filteredInspectorData[letter], !inspectors.isEmpty {
                               Section {
                                   
                                   ForEach(inspectors.sorted { $0.name < $1.name }) { item in
                                       Button {
                                                   path.append(.inspectorProfile(item.name))
                                               } label: {
                                                   
                                                   
                                                AllCard(title: item.name, count: item.count)
                                     
                                       }
                                       .buttonStyle(PlainButtonStyle())
                                       .padding(.bottom, 16)
                                   }
                               } header: {
                                   ZStack {
                                       Rectangle()
                                           .fill(Color.white)
                                           .ignoresSafeArea()
                                       
                                       VStack {
                                           Spacer()
                                           Text(letter)
                                               .font(.title3)
                                               .padding(.horizontal, 12)
                                               .frame(maxWidth: .infinity, alignment: .leading)
                                               .foregroundStyle(.color4)
                                           Spacer()
                                       }
                                       .frame(height: 40)
                                   }
                               }
                               
                           }
                       }
                   }
                   .padding(.horizontal)
                }
                .scrollDismissesKeyboard(.interactively)
                .scrollIndicators(.hidden)
                .padding(.bottom)
                .background(.clear)
              
            }
        }
        .keyboardAdaptive()
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}

struct InstpectorData: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let count: Int
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: InstpectorData, rhs: InstpectorData) -> Bool {
        lhs.id == rhs.id
    }
}




struct AllCard: View{
    
    var title: String
    var count: Int?
    
    var body: some View{
        
        HStack(alignment: .center) {
            
            VStack(alignment: .leading, spacing: 5){
                
                
                Text(title)
                    .font(.body)
                    .foregroundStyle(.color4)
             
                
                
                Text("\(count ?? 0) report\(count ?? 0 > 1 ? "s" : "")")
                    .font(.callout)
                    .foregroundColor(.gray)
                
                
            }
            
            Spacer()
            Image(systemName: "chevron.right.circle")
                .font(.title2)
                .foregroundColor(.color1)
            
            
        }
        .padding()
        .background(.color0.opacity(0.3))
        .cornerRadius(10)
    }
}
