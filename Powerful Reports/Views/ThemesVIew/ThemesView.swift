//
//  ThemesView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 25/11/2024.
//

import SwiftUI

struct ThemesView: View {
    
    var body: some View {
      
        VStack{
            CustomHeaderVIew(title: "All Themes")
            ScrollView {
                
            }
            
            Spacer()
        }
        .ignoresSafeArea()
        .navigationBarHidden(true)
    }
}

#Preview {
    ThemesView()
}
