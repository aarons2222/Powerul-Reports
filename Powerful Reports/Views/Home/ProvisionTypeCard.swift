//
//  ProvisionTypeCard.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 19/11/2024.
//
import SwiftUI
import Charts
import Combine


struct ProvisionTypeCard: View {
    let data: [OutcomeData]
    @StateObject private var chartTwoObserver = VisibilityObserver(id: "chart2")
    var viewModel: InspectionReportsViewModel
    
    
    @State private var animationAmount: CGFloat = 0
    
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Provision Types")
                    .font(.title3)
                    .fontWeight(.regular)
                    .foregroundColor(.color4)
                Spacer()
                Image(systemName: "plus.circle")
                    .font(.title2)
                    .foregroundColor(.color1)
            }
            .padding(.bottom, 20)
            
            Chart(data) { item in
                SectorMark(
                    angle: .value("Count", CGFloat(item.count) * animationAmount),
                    angularInset: 1
                    
                )
                .cornerRadius(5)
                .foregroundStyle(item.color)
            }
            .frame(height: 200)
            
            .monitorVisibility(chartTwoObserver)
            
            ForEach(data) { item in
                HStack {
                    Image(systemName: "largecircle.fill.circle")
                        .font(.body)
                        .foregroundStyle(item.color)
                    Text(item.outcome)
                        .font(.body)
                        .foregroundColor(.color4)
                    Spacer()
                    Text("\(viewModel.calculatePercentage(count: item.count, forProvisionData: data), specifier: "%.1f")%")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .cardBackground()
        .onChange(of: chartTwoObserver.isVisible) { _, isVisible in
            if isVisible {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animationAmount = 1.0
                }
            } else {
                animationAmount = 0
            }
        }
    }
}
