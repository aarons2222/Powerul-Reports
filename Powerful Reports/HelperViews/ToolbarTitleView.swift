//
//  ToolbarTitleView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 19/11/2024.
//

import SwiftUI

struct ToolbarTitleView: ToolbarContent {
    let icon: String
    let title: String
    let iconColor: Color
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.title3)
                Spacer()
            }
        }
    }
}


struct ToolbarTitleView2: View {
    let icon: String
    let title: String
    let iconColor: Color
    
    var body: some View {
      
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.title3)
                Spacer()
            }
        
    }
}
