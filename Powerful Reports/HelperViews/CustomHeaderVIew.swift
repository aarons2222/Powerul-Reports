//
//  CustomHeaderVIew.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 22/11/2024.
//

import SwiftUI

struct CustomHeaderVIew: View {
    
    @Environment(\.presentationMode) var presentationMode

    var title: String

    
    var body: some View {
        
     
            
            
            
        ZStack{
            Rectangle()
                .fill(.color1)
                .frame(height: 150) // Set explicit height
                .overlay(alignment: .leading) {
                    Circle()
                        .fill(.color1)
                        .overlay {
                            Circle()
                                .fill(.white.opacity(0.2))
                        }
                        .scaleEffect(2, anchor: .topLeading)
                        .offset(x: -50, y: -40)
                }
                .clipShape(Rectangle())
            
            VStack{
                Spacer()
                
                HStack{
             
                        
                        Button{
                            presentationMode.wrappedValue.dismiss()
                        }label: {
                            Image(systemName: "chevron.backward.circle.fill")
                                .font(.title)
                                .fontWeight(.regular)
                                .foregroundStyle(.white)
                                .opacity(0.6)
                        }
                    
                    
                    
                 

                    Text(title)
                        .font(.largeTitle)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                 
                }
                
            }
            .padding()
            .background(.clear)
            .frame(height: 150)
        }
    }
    
}

#Preview {
    CustomHeaderVIew(title: "Hello")
}
