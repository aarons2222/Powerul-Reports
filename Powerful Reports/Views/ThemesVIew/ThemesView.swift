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
    let percentage: Double
}

struct ThemesView: View {
    private let themeGroups: [ProcessedThemeGroup]
    @State private var expandedId: UUID? = nil
    @State private var selectedTheme: String? = nil
    @State private var animateCards = false
    
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
                theme.1 >= min && theme.1 < max
            }.map { $0.0 }
            
            guard !themesInRange.isEmpty else { return nil }
            
            let title: [String]
            let percentage: Double
            switch max {
            case 100.1:
                title = ["Universal", "Found in over 75% of reports"]
                percentage = 100
            case 75.0:
                title = ["Very Common", "Found in 50-75% of reports"]
                percentage = 75
            case 50.0:
                title = ["Frequent", "Found in 25-50% of reports"]
                percentage = 50
            case 25.0:
                title = ["Moderate", "Found in 5-25% of reports"]
                percentage = 25
            case 5.0:
                title = ["Uncommon", "Found in 1-5% of reports"]
                percentage = 5
            case 1.0:
                title = ["Rare", "Found in less than 1% of reports"]
                percentage = 1
            default:
                title = ["Other Themes", ""]
                percentage = 0
            }
            
            return ProcessedThemeGroup(title: title, themes: themesInRange.sorted(), percentage: percentage)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CustomHeaderVIew(title: "All Themes")
            
            // Themes List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(themeGroups.enumerated().reversed()), id: \.1.id) { index, group in
                        ThemeCardView(
                            group: group,
                            isExpanded: expandedId == group.id,
                            selectedTheme: $selectedTheme,
                            index: index,
                            totalCount: themeGroups.count
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                expandedId = expandedId == group.id ? nil : group.id
                            }
                        }
                       
                    }
                }
                .padding()
            }
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
        .onAppear {
            withAnimation {
                animateCards = true
            }
        }
    }
}

struct ThemeCardView: View {
    let group: ProcessedThemeGroup
    let isExpanded: Bool
    @Binding var selectedTheme: String?
    let index: Int
    let totalCount: Int
    @State private var showProgress = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.title[0])
                        .font(.headline)
                        .fontWeight(.regular)
                    Text(group.title[1])
                        .font(.subheadline)
                        .fontWeight(.regular)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.down.circle")
                    .font(.title2)
                    .foregroundColor(.color1)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .animation(.spring(), value: isExpanded)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(Color.color1)
                        .frame(width: showProgress ? geometry.size.width * (group.percentage / 100) : 0, height: 6)
                        .cornerRadius(3)
                        .animation(.easeInOut(duration: 1.0).delay(0.3), value: showProgress)
                }
            }
            .frame(height: 6)
            .onAppear {
                showProgress = true
            }
            
            if isExpanded {
                // Themes Grid
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                    ForEach(group.themes, id: \.self) { theme in
                        Button(action: {
                            withAnimation {
                                selectedTheme = selectedTheme == theme ? nil : theme
                            }
                        }) {
                            Text(theme)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .cardBackground()
                                .foregroundColor(selectedTheme == theme ? .color1 : .primary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .cardBackground()
        .scaleEffect(selectedTheme != nil && !group.themes.contains(selectedTheme!) ? 0.95 : 1.0)
        .opacity(selectedTheme != nil && !group.themes.contains(selectedTheme!) ? 0.7 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTheme)
    }
}
