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
                if item.outcome != "empty" {
                    HStack {
                        Image(systemName: "largecircle.fill.circle")
                            .font(.body)
                            .foregroundStyle(item.color)
                        Text(item.outcome)
                            .font(.body)
                            .foregroundColor(.color4)
                        Spacer()
                        Text("\(viewModel.calculatePercentage(item.count))%")
                            .font(.body)
                            .foregroundColor(.gray)
                    }
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

// MARK: - VisibilityObserver
class VisibilityObserver: ObservableObject {
    let id: String
    @Published var isVisible = false
    
    init(id: String) {
        self.id = id
    }
    
    func handleVisibilityChange(_ isVisible: Bool) {
        print("Visibility changed for \(id): \(isVisible)")
    }
}

// MARK: - View Extension
extension View {
    func monitorVisibility(_ observer: VisibilityObserver) -> some View {
        modifier(VisibilityModifier(observer: observer))
    }
}

// MARK: - Visibility Modifier
struct VisibilityModifier: ViewModifier {
    @ObservedObject var observer: VisibilityObserver
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: proxy.frame(in: .global)) { oldFrame, newFrame in
                            observer.isVisible = UIScreen.main.bounds.intersects(newFrame)
                        }
                }
            )
    }
}
