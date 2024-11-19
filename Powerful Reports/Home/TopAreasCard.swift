//
//  TopAreasCard.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 19/11/2024.
//

import SwiftUI

struct TopAreasCard: View {
    let reports: [Report]
    
    // Compute area statistics
    var areaData: [AreaData] {
        // Group reports by local authority
        let areaCounts = Dictionary(grouping: reports) { $0.localAuthority }
            .mapValues { $0.count }
            .filter { !$0.key.isEmpty } // Filter out empty authority names
        
        // Sort by count and take top 5
        return areaCounts.sorted { $0.value > $1.value }
            .prefix(5)
            .map { AreaData(area: $0.key, count: $0.value) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "map.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("Most Inspected Areas")
                    .font(.headline)
                Spacer()
            }
            
            Divider()
            
            // List of areas
            VStack(alignment: .leading, spacing: 8) {
                ForEach(areaData) { item in
                    HStack(alignment: .center) {
                        Text("\(item.area)")
                            .font(.system(.body, design: .rounded))
                        
                        Spacer()
                        
                        Text("\(item.count)")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.gray)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )
                    }
                    if item.id != areaData.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}



// Data model for area statistics
struct AreaData: Identifiable {
    let id = UUID()
    let area: String
    let count: Int
}

