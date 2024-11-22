//
//  ProvisionTypeCard.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 19/11/2024.
//
import SwiftUI
import Charts

struct ProvisionTypeCard: View {
    let data: [OutcomeData]
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
//                Image(systemName: "building.2")
//                    .font(.title2)
//                    .foregroundColor(.purple)
                Text("Provision Types")
                    .font(.headline)
                Spacer()
            }
            
            Chart(data) { item in
                SectorMark(
                    angle: .value("Count", item.count)
                )
                .foregroundStyle(item.color)
            }
            .frame(height: 100)
            
            ForEach(data) { item in
                
                if item.outcome != "empty"{
                    HStack {
                        Circle()
                            .fill(item.color)
                            .frame(width: 8, height: 8)
                        Text(item.outcome)
                            .font(.caption)
                        Spacer()
                        Text("\(item.count)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    .onAppear(){
                        print("Type \(item.outcome)")
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
