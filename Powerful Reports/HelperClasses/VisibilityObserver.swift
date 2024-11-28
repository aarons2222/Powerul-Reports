//
//  VisibilityObserver.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 28/11/2024.
//

import SwiftUI

// MARK: - VisibilityObserver
class VisibilityObserver: ObservableObject {
    let id: String
    @Published var isVisible = false
    
    init(id: String) {
        self.id = id
    }
    
    func handleVisibilityChange(_ isVisible: Bool) {
        print("Visibility changed for \(id): \(isVisible)")
    }
}

// MARK: - View Extension
extension View {
    func monitorVisibility(_ observer: VisibilityObserver) -> some View {
        modifier(VisibilityModifier(observer: observer))
    }
}

// MARK: - Visibility Modifier
struct VisibilityModifier: ViewModifier {
    @ObservedObject var observer: VisibilityObserver
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: proxy.frame(in: .global)) { oldFrame, newFrame in
                            observer.isVisible = UIScreen.main.bounds.intersects(newFrame)
                        }
                }
            )
    }
}
