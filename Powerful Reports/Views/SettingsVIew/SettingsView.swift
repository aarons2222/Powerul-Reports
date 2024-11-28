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
            CustomHeaderVIew(title: "Settings")
            
            ScrollView{
                
                SettingsRow()
                    .background(.color0.opacity(0.3))
                SettingsRow()
                    .background(.color0.opacity(0.3))
                
      
            }
            .padding()
            

           
            
            Spacer()
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SettingsView()
}

struct SettingsRow: View {
    
    
    var body: some View {
        
        HStack(alignment: .center) {
            
            VStack(alignment: .leading, spacing: 5){
                
                
                Text("About")
                    .font(.body)
                    .foregroundStyle(.color4)
                
                
                
                Text("sss")
                    .font(.callout)
                    .foregroundColor(.gray)
                
                
            }
            
            Spacer()
            Image(systemName: "chevron.right.circle")
                .font(.title2)
                .foregroundColor(.color1)
            
            
        }
        .padding()
   
        .cornerRadius(10)
    }
}
