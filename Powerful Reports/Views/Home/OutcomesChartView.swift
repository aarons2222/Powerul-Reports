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
    var viewModel: InspectionReportsViewModel
    
    @State private var animationPhase: Double = 0
    @State private var displayData: [OutcomeData] = []
    @State private var previousData: [OutcomeData] = []
    @State private var isAnimating = false
    @State private var legendOpacities: [String: Double] = [:]

    
    private var outcomeData: [OutcomeData] {
        let processedReports = reports.map { report -> (String, Color) in
            if !report.outcome.isEmpty {
                return (report.outcome, report.outcome == "Met" ? .color2 : .color6)
            } else if let overallRating = report.ratings.first(where: { $0.category == RatingCategory.overallEffectiveness.rawValue }),
                      let ratingValue = RatingValue(rawValue: overallRating.rating) {
                return (overallRating.rating, ratingValue.color)
            }
            return ("Unknown", .gray)
        }
        
        let outcomeCounts = Dictionary(grouping: processedReports) { $0.0 }
        return outcomeCounts.map { outcome, reports in
            OutcomeData(
                outcome: outcome,
                count: reports.count,
                color: reports.first?.1 ?? .gray
            )
        }.sorted { $0.count > $1.count }
    }
    
    private func calculatePercentage(_ count: Int) -> Double {
        let total = displayData.reduce(0) { $0 + $1.count }
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
            
            Chart(displayData) { data in
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
                       ForEach(Array(displayData.enumerated()), id: \.element.id) { index, data in
                           HStack {
                               Image(systemName: "largecircle.fill.circle")
                                   .font(.body)
                                   .foregroundStyle(data.color)
                               
                               Text(data.outcome)
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
               .onAppear {
                   displayData = outcomeData
                   previousData = outcomeData
                   
                   // Animate chart
                   DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                       withAnimation(.spring(duration: 0.6)) {
                           animationPhase = 1
                       }
                   }
                   
                   // Animate legend items with staggered delay
                   for (index, item) in displayData.enumerated() {
                       DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1 + 0.3) {
                           withAnimation(.spring(duration: 0.6)) {
                               legendOpacities[item.outcome] = 1
                           }
                       }
                   }
               }
               .onChange(of: outcomeData) {
                   guard !isAnimating else { return }
                   
                   isAnimating = true
                   previousData = displayData
                   
                   // Reset legend opacities
                   for item in displayData {
                       legendOpacities[item.outcome] = 0
                   }
                   
                   withAnimation(.linear(duration: 0.6)) {
                       animationPhase = 0
                   } completion: {
                       displayData = outcomeData
                       
                       // Animate new legend items
                       for (index, item) in displayData.enumerated() {
                           DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                               withAnimation(.spring(duration: 0.6)) {
                                   legendOpacities[item.outcome] = 1
                               }
                           }
                       }
                       
                       withAnimation(.linear(duration: 0.6)) {
                           animationPhase = 1
                       } completion: {
                           isAnimating = false
                       }
                   }
               }
           }
       }


