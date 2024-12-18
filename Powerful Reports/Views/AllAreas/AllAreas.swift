//
//  AllAreas.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 19/11/2024.
//

import SwiftUI
import UIKit

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
    
    @Environment(\.dismiss) private var presentationMode

    
    private let startColor: Color = .color2
    private let endColor: Color = .color1
    
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
    
    @State private var searchText = ""
    private var filteredAreaData: [String: [AreaInformation]] {
        if searchText.isEmpty {
            return groupedAreaData
        }
        
        let filteredData = groupedAreaData.flatMap { _, areas in
            areas.filter { area in
                area.name.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Regroup filtered results by first letter
        return Dictionary(grouping: filteredData) {
            String($0.name.prefix(1)).uppercased()
        }
    }
    
    @Binding var path: [NavigationPath]
    init(reports: [Report], path: Binding<[NavigationPath]>) {
        self.reports = reports
        self._path = path
    }
 
     
     var body: some View {
    
             VStack(alignment: .leading, spacing: 0) {
                 CustomHeaderVIew(title: "Local Authorities")
                 
                
                 
                 SearchBar(searchText: $searchText, placeHolder: "Search \(Set(reports.map { $0.localAuthority }).count) Local Authorities...")
                 
                 
                 if filteredAreaData.isEmpty {
                     
                     HStack {
                         Spacer()
                         
                         VStack{
                           
                             
                             
                             Text("Area not found")
                                 .font(.title)
                                 .foregroundStyle(.color2)
                         }
                         Spacer()
                     }
                     .padding(.top, 30)
                   Spacer()
                     
                     
            
                                
                 }else{
                     
                     ScrollView {
                         
                         LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                             ForEach(Array(filteredAreaData.keys.sorted()), id: \.self) { letter in
                                 if let areas = filteredAreaData[letter]?.sorted(by: { $0.name < $1.name }) {
                                     Section {
                                         ForEach(Array(zip(areas.indices, areas)), id: \.1.id) { index, item in
                                             
                                             Button {
                                                 path.append(.areaProfile(item.name))
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
