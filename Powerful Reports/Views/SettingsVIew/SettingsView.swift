//
//  SettingsView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 22/11/2024.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
       
        VStack{
            CustomHeaderVIew(title: "Settings", showBackButton: false)
            
            Spacer()
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SettingsView()
}
