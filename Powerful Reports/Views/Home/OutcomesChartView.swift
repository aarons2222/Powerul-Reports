//
//  InspectionOutcomesChartView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 19/11/2024.
//

import SwiftUI
import Charts

struct OutcomesChartView: View {
    let reports: [Report]
    @ObservedObject var viewModel: InspectionReportsViewModel
    
    @State private var animationPhase: Double = 0
    @State private var legendOpacities: [String: Double] = [:]
    
    private func calculatePercentage(_ count: Int) -> Double {
        let total = viewModel.outcomesDistribution.reduce(0) { $0 + $1.count }
        guard total > 0 else { return 0 }
        let percentage = Double(count) / Double(total) * 100
        return (percentage * 10).rounded() / 10
    }
    
    var body: some View {

            VStack(alignment: .leading, spacing: 12) {
                HStack {

                    Text("Inspection Outcomes")
                        .font(.title3)
                        .fontWeight(.regular)
                        .foregroundColor(.color4)
                    Spacer()
                    
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundColor(.color1)
                }
                .padding(.bottom, 20)
        
                Chart(viewModel.outcomesDistribution) { data in
                    SectorMark(
                        angle: .value("Count", Double(data.count) * animationPhase),
                        innerRadius: 70,
                        angularInset: 1
                    )
                    .cornerRadius(5)
                    .foregroundStyle(data.color)
                }
                .frame(height: 250)
                
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(viewModel.outcomesDistribution.enumerated()), id: \.element.id) { index, data in
                        HStack {
                            Image(systemName: "largecircle.fill.circle")
                                .font(.body)
                                .foregroundStyle(data.color)
                            
                            Text(data.outcome.capitalized)
                                .font(.body)
                                .foregroundColor(.color4)
                            
                            Spacer()
                            
                            Text("\(calculatePercentage(data.count), specifier: "%.1f")%")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                        .opacity(legendOpacities[data.outcome, default: 0])
                        .offset(y: legendOpacities[data.outcome, default: 0] == 0 ? 20 : 0)
                    }
                }
                .padding(.top, 8)
            
        }
        .padding()
        .cardBackground()
        .onChange(of: viewModel.outcomesDistribution) {
            guard !viewModel.outcomesDistribution.isEmpty else { return }
            
            // Reset animation state
            withAnimation(.linear(duration: 0.3)) {
                animationPhase = 0
            }
            
            // Reset legend opacities
            for item in viewModel.outcomesDistribution {
                legendOpacities[item.outcome] = 0
            }
            
            // Animate in new data after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // Animate chart
                withAnimation(.linear(duration: 0.5)) {
                    animationPhase = 1
                }
                
                // Animate legend items with stagger
                for (index, item) in viewModel.outcomesDistribution.enumerated() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                        withAnimation(.linear(duration: 0.4)) {
                            legendOpacities[item.outcome] = 1
                        }
                    }
                }
            }
        }
        .onAppear {
            guard !viewModel.outcomesDistribution.isEmpty else { return }
            
            // Initial animation
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                withAnimation(.linear(duration: 0.4)) {
                    animationPhase = 1
                }
                
                for (index, item) in viewModel.outcomesDistribution.enumerated() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                        withAnimation(.linear(duration: 0.3)) {
                            legendOpacities[item.outcome] = 1
                        }
                    }
                }
            }
        }
    }
}
