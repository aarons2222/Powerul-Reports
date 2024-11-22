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
//                Image(systemName: "list.bullet")
//                    .font(.title2)
                   // .foregroundColor(.green)
                Text("Top Themes")
                    .font(.headline)
                Spacer()
            }
            
            Spacer()
            
            ForEach(Array(themes.enumerated()), id: \.1.0) { index, theme in
                HStack {
                    Text("\(index + 1)")
                    
                    Text(theme.0)
                        .lineLimit(1)
                }
                .font(.caption)
            }
        }
        .padding()
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}
