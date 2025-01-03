//
//  GlobalButton.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 28/11/2024.
//

import SwiftUI

struct GlobalButton: View {
    // Properties
    var title: String
    var backgroundColor: Color = .color1
    var foregroundColor: Color = .white
    var verticalPadding: CGFloat = 14
    var horizontalPadding: CGFloat = 0
    var action: () -> Void
    

    // Body
    var body: some View {
        Button(action: {
            action()
        }) {
            Text(title)
                .foregroundColor(foregroundColor)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.vertical, verticalPadding)
                .frame(maxWidth: .infinity)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 25))
        }
        .frame(height: 50)
    
    }
}

#Preview {
    GlobalButton(title: "Press Me", action: {
           print("Button pressed!")
       })
}
