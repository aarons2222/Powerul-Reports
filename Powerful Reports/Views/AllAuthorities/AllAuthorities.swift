//
//  AllAuthorities.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 19/11/2024.
//

import SwiftUI
import UIKit

struct AuthorityProfile: Identifiable {
    let id = UUID()
    let name: String
    let totalInspections: Int
    let inspectors: [String: Int]
    let grades: [String: Int]
    let provisionTypes: [String: Int]
    let themes: [(topic: String, frequency: Int)]  // Added themes
}

struct AuthorityInformation: Identifiable {
    let id = UUID()
    let name: String
    let count: Int
}

struct AllAuthorities: View {
    let reports: [Report]
    
    @Environment(\.dismiss) private var presentationMode

    
    private let startColor: Color = .color2
    private let endColor: Color = .color1
    
    private var groupedAuthorityData: [String: [AuthorityInformation]] {
        let authorityCounts = Dictionary(grouping: reports) { $0.localAuthority }
            .mapValues { $0.count }
            .filter { !$0.key.isEmpty }
        
        let authorityData = authorityCounts.sorted { $0.value > $1.value }
            .map { AuthorityInformation(name: $0.key, count: $0.value) }
        
        return Dictionary(grouping: authorityData) {
            String($0.name.prefix(1)).uppercased()
        }
    }
    
    @State private var searchText = ""
    private var filteredAuthorityData: [String: [AuthorityInformation]] {
        if searchText.isEmpty {
            return groupedAuthorityData
        }
        
        let filteredData = groupedAuthorityData.flatMap { _, authorities in
            authorities.filter { authority in
                authority.name.localizedCaseInsensitiveContains(searchText)
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
                 
                 
                 if filteredAuthorityData.isEmpty {
                     
                     HStack {
                         Spacer()
                         
                         VStack{
                           
                             
                             
                             Text("Authority not found")
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
                             ForEach(Array(filteredAuthorityData.keys.sorted()), id: \.self) { letter in
                                 if let authorities = filteredAuthorityData[letter]?.sorted(by: { $0.name < $1.name }) {
                                     Section {
                                         ForEach(Array(zip(authorities.indices, authorities)), id: \.1.id) { index, item in
                                             
                                             Button {
                                                 path.append(.authorityProfile(item.name))
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
