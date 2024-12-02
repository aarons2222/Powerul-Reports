//
//  ThemesCard.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 19/11/2024.
//

import SwiftUI


struct ThemeRankingCard: View {
    let themes: [(String, Int)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {

                Text("Trending Themes")
                    .font(.title3)
                    .fontWeight(.regular)
                    .foregroundColor(.color4)
                Spacer()
                
                Image(systemName: "plus.circle")
                    .font(.title2)
                    .foregroundColor(.color1)
            }
            .padding(.bottom, 20)
            
            
            
            ForEach(Array(themes.enumerated()), id: \.1.0) { index, theme in
                HStack {
                    Text("\(index + 1)")
                        .foregroundStyle(.gray)
                        .padding(.trailing, 8)
                    
                    Text(theme.0)
                        .foregroundStyle(.color4)
                }
              
                .font(.body)
            }
        }
        .padding()
        .cardBackground()

    }
}



struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.color0.opacity(0.3))
            .cornerRadius(25)
            .shadow(color: .color4.opacity(0.05), radius: 4)
    }
}

extension View {
    func cardBackground() -> some View {
        modifier(CardBackground())
    }
}
