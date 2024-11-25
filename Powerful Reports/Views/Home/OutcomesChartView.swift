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
    @State private var animationPhase: Double = 0
    @State private var previousData: [OutcomeData] = []
    @State private var isAnimating = false
    @State private var displayData: [OutcomeData] = []
    @State private var hasInitialized = false
    
    var viewModel: InspectionReportsViewModel


    var outcomeData: [OutcomeData] {
        // Process each report to exactly one outcome
        let processedReports = reports.map { report -> (String, Color) in
            // Check for Met/Not Met outcome first
            if !report.outcome.isEmpty {
                return (report.outcome, report.outcome == "Met" ? .yellow : .red)
            }
            // If no Met/Not Met, then it must have an Overall Effectiveness rating
            else if let overallRating = report.ratings.first(where: { $0.category == RatingCategory.overallEffectiveness.rawValue }) {
                if let ratingValue = RatingValue(rawValue: overallRating.rating) {
                    return (overallRating.rating, ratingValue.color)
                }
            }
            
            // This should never happen as each report must have one or the other
            return ("Unknown", .gray)
        }
        
        // Count frequencies and sort
        let outcomeCounts = Dictionary(grouping: processedReports) { $0.0 }
        return outcomeCounts.map { outcome, reports in
            OutcomeData(
                outcome: outcome,
                count: reports.count,
                color: reports.first?.1 ?? .gray
            )
        }.sorted { $0.count > $1.count }
    }

    
 
    @State private var appear = false
    
    
    
    
    /// CHART ANIMATION

    private func startInitialAnimation() {
        displayData = outcomeData
        previousData = outcomeData
        animationPhase = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(duration: 0.6)) {
                animationPhase = 1
            }
        }
    }
    
    private func handleDataChange() {
        guard !isAnimating else { return }
        guard !previousData.isEmpty else { return }
        
        isAnimating = true
        previousData = displayData
        
        // Break animation into two phases
        animatePhaseOne {
            animatePhaseTwo()
        }
    }
    
    private func animatePhaseOne(completion: @escaping () -> Void) {
        withAnimation(.linear(duration: 0.6)) {
            animationPhase = 0
        } completion: {
            displayData = outcomeData
            completion()
        }
    }
    
    private func animatePhaseTwo() {
        withAnimation(.linear(duration: 0.6)) {
            animationPhase = 1
        } completion: {
            isAnimating = false
        }
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
                        .onDisappear {
                            withAnimation(.linear(duration: 0.6)) {
                                animationPhase = 0
                            }
                        }
                        .onAppear {
                            startInitialAnimation()
                        }
                        .onChange(of: outcomeData) {
                            handleDataChange()
                        }
            
            
            
            
            

            VStack(alignment: .leading, spacing: 4) {
                ForEach(outcomeData) { data in
                    HStack {
                        Image(systemName: "largecircle.fill.circle")
                            .font(.body)
                            .foregroundStyle(data.color)
                            .transition(.slide)
                        
                        Text(data.outcome)
                            .font(.body)
                            .foregroundColor(.color4)
                            .transition(.slide)
                        
                        Spacer()
                        
                        Text("\(viewModel.calculatePercentage(data.count))%")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .transition(.slide)
                    }
                    .animation(.easeInOut(duration: 0.6), value: outcomeData)
                }
            }
            .animation(.easeInOut(duration: 0.6), value: outcomeData.count)
            .padding(.top, 8)
            
        }
        .padding()
        .cardBackground()
    }

}


