//
//  CardView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 28/11/2024.
//
import SwiftUI



struct CustomCardView<Content: View>: View {
    let title: String
    let content: Content
    let navigationLink: AnyView?
    
    init(_ title: String,
         navigationLink: AnyView? = nil,
         @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
        self.navigationLink = navigationLink
    }
    
    var body: some View {
        
        
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.regular)
                    .foregroundColor(.color4)
                Spacer()
                
                if let nav = navigationLink {
                    nav
                }
            }
            .padding(.bottom, 15)
            
            content
        }
        .padding()
        .cardBackground()
    }
}
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.color0.opacity(0.3))
            .cornerRadius(20)
            .shadow(color: .color4.opacity(0.05), radius: 4)
    }
}

extension View {
    func cardBackground() -> some View {
        modifier(CardBackground())
    }
}
