//
//  SearchBar.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 29/11/2024.
//
import SwiftUI
import Combine

struct SearchBar: View {
    @Binding var searchText: String
    var placeHolder: String
    
    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(.color3.opacity(0.9))
                
                TextField(placeHolder, text: $searchText)
                    .autocorrectionDisabled()
                    .accentColor(.color3.opacity(0.9))
      
                
              
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.color3.opacity(0.3))
                    }
                }
            }
            .padding(12)
            .foregroundStyle(.color4)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .background(.color0.opacity(0.1))
    }
}

