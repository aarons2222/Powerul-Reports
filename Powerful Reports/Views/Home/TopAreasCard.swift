//
//  TopAuthoritiesCard.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 19/11/2024.
//

import SwiftUI

struct TopAuthoritiesCard: View {
    let reports: [Report]
    
    // Compute area statistics
    var authorityData: [AuthorityData] {
        // Group reports by local authority
        let authorityCounts = Dictionary(grouping: reports) { $0.localAuthority }
            .mapValues { $0.count }
            .filter { !$0.key.isEmpty } // Filter out empty authority names
        
        // Sort by count and take top 5
        return authorityCounts.sorted { $0.value > $1.value }
            .prefix(5)
            .map { AuthorityData(authority: $0.key, count: $0.value) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Local Authority with the Most Inspections")
                    .font(.title3)
                    .fontWeight(.regular)
                    .foregroundColor(.color4)
                Spacer()
                Image(systemName: "plus.circle")
                    .font(.title2)
                    .foregroundColor(.color1)
            }
            .padding(.bottom, 20)
            
       
            
            // List of areas
            ScrollView{
                
                ForEach(0..<authorityData.count, id: \.self) { index in
                    let item = authorityData[index]
                    HStack(alignment: .center) {
                        Text("\(item.authority)")
                            .font(.body)
                            .foregroundStyle(.color4)
                        
                        Spacer()
                        
                        Text("\(item.count)")
                            .font(.body)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                        
                    }
                    
                    if index < authorityData.count - 1 {
                        Divider()
                    }
                    
                }
            }
        }
        .padding()
        .cardBackground()
    }
}



// Data model for area statistics
struct AuthorityData: Identifiable {
    let id = UUID()
    let authority: String
    let count: Int
}

