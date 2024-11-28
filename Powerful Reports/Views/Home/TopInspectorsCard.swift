//
//  TopInspectorsCard.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 19/11/2024.
//

import SwiftUI

struct TopInspectorsCard: View {
    let reports: [Report]
    
    // Compute area statistics
    var inspectorData: [InstpectorData] {
        // Group reports by local authority
        let inspectorCounts = Dictionary(grouping: reports) { $0.inspector }
            .mapValues { $0.count }
            .filter { !$0.key.isEmpty } // Filter out empty authority names
        
        // Sort by count and take top 5
        return inspectorCounts.sorted { $0.value > $1.value }
            .prefix(5)
            .map { InstpectorData(name: $0.key, count: $0.value) }
    }
    
  
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Most Active Inspectors")
                    .font(.title3)
                    .fontWeight(.regular)
                    .foregroundColor(.color4)
                
                Spacer()
                Image(systemName: "plus.circle")
                    .font(.title2)
                    .foregroundColor(.color1)
            }
            .padding(.bottom, 20)
            
       
            
            ScrollView{
                
                
                ForEach(0..<inspectorData.count, id: \.self) { index in
                    let item = inspectorData[index]
                    
                    HStack(alignment: .center) {
                        Text("\(item.name)")
                            .font(.body)
                            .foregroundStyle(.color4)
                        
                        Spacer()
                        
                        Text("\(item.count)")
                            .font(.body)
                            .foregroundColor(.gray)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                        
                    }
                    
                    if index < inspectorData.count - 1 {
                        Divider()
                    }
                    
                }
                
            }
        }
        .padding()
        .cardBackground()
        
    }
}

