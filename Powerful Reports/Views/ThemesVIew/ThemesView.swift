//
//  ThemesView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 25/11/2024.
//

import SwiftUI

struct ProcessedThemeGroup: Identifiable {
    let id = UUID()
    let title: [String]
    let themes: [String]
}

struct ThemesView: View {
    private let themeGroups: [ProcessedThemeGroup]
    @State private var expandedId: Int? = nil
    
    init(themes: [(String, Double)]) {
        // Define ranges with min and max values (exclusive)
        let thresholds = [
            (75.0, 100.1), // Universal (75-100%)
            (50.0, 75.0),  // Very Common (50-75%)
            (25.0, 50.0),  // Frequent (25-50%)
            (5.0, 25.0),   // Moderate (5-25%)
            (1.0, 5.0),    // Uncommon (1-5%)
            (0.0, 1.0)     // Rare (<1%)
        ]
        
        self.themeGroups = thresholds.compactMap { range -> ProcessedThemeGroup? in
            let (min, max) = range
            
            let themesInRange = themes.filter { theme in
                theme.1 >= min && theme.1 < max  // Use < instead of <= for exclusive upper bound
            }.map { $0.0 }
            
            guard !themesInRange.isEmpty else { return nil }
            
            let title: [String]
            switch max {
            case 100.1:
                title = ["Universal", "Found in over 75% of reports"]
            case 75.0:
                title = ["Very Common", "Found in 50-75% of reports"]
            case 50.0:
                title = ["Frequent", "Found in 25-50% of reports"]
            case 25.0:
                title = ["Moderate", "Found in 5-25% of reports"]
            case 5.0:
                title = ["Uncommon", "Found in 1-5% of reports"]
            case 1.0:
                title = ["Rare", "Found in less than 1% of reports"]
            default:
                title = ["Other Themes", ""]
            }
            
            return ProcessedThemeGroup(title: title, themes: themesInRange.sorted())
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CustomHeaderVIew(title: "All Themes")
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(themeGroups.enumerated().reversed()), id: \.1.id) { index, group in
                        ExpandingCardView(
                            item: CardItem(
                                id: UUID(),
                                title: group.title,
                                items: group.themes,
                                color: .color2.opacity(0.4 + 0.4 * (1 - Double(index) / Double(themeGroups.count)))

                                    
                            ),
                            isExpanded: expandedId == index
                        )
                        .animation(.easeInOut(duration: 0.3), value: expandedId)
                        .onTapGesture {
                            expandedId = expandedId == index ? nil : index
                        }
                       
                    }
                }
                .padding()
                .animation(.easeInOut(duration: 0.3), value: expandedId)
            }
            Spacer()
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}

struct CardItem: Identifiable {
    let id: UUID
    let title: [String]
    let items: [String]
    let color: Color
}

struct ExpandingCardView: View {
    let item: CardItem
    let isExpanded: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
        
            Text(item.title.first ?? "")
                .font(.title2)
                .fontWeight(.regular)
                .padding(.top, isExpanded ? 10 : 0)
                .padding(.horizontal)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            
            Text(item.title.last ?? "")
                .font(.body)
                .foregroundColor(.white)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if isExpanded {
                themesListView
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity)
        .background(backgroundView)
        .cornerRadius(14)
        .shadow(color: item.color.opacity(0.4), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
    }
    
    private var themesListView: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(item.items, id: \.self) { item in
                HStack {
                    Circle()
                        .fill(.white.opacity(0.9))
                        .frame(width: 6, height: 6)
                    Text(item)
                        .font(.body)
                }
            }
        }
        .padding(20)
        .foregroundColor(.white.opacity(0.9))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [item.color.opacity(0.8), item.color]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
