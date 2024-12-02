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
        let thresholds = [(0.0, 100.0), (0.0, 74.9), (0.0, 49.9), (0.0, 24.9), (0.0, 4.9), (0.0, 0.9)]
        
        self.themeGroups = thresholds.compactMap { range -> ProcessedThemeGroup? in
            let (min, max) = range
            
            let themesInRange = themes.filter { theme in
                theme.1 >= min && theme.1 <= max
            }.map { $0.0 }
            
            guard !themesInRange.isEmpty else { return nil }
            
            let title: [String]
            switch max {
            case 100.0:
                title = ["Universal", "Found in 100% of reports)"]
            case 74.9:
                title = ["Very Common", "Found in 75% of reports"]
            case 49.9:
                title = ["Frequent", "Found in 50% of reports)"]
            case 24.9:
                title = ["Moderate", "Found in 25% of reports)"]
            case 4.9:
                title = ["Uncommon", "Found in 5% of reports)"]
            case 0.9:
                title = ["Rare", "Found in 1% of reports"]
            default:
                title = ["Other Themes", ""]
            }
            
            return ProcessedThemeGroup(title: title, themes: themesInRange.sorted())
        }
    }
    
    var body: some View {
        VStack {
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
        VStack(alignment: .leading, spacing: 10) {
        
            Text(item.title.first ?? "")
                .font(.title)
                .fontWeight(.regular)
                .padding(.top, isExpanded ? 10 : 0)
                .padding(.horizontal)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            
            Text(item.title.last ?? "")
                .font(.callout)
                .foregroundColor(.white)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if isExpanded {
                themesListView
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 100)
        .background(backgroundView)
        .cornerRadius(20)
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
