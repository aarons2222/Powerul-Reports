//
//  KeyboardAdaptive.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 03/12/2024.
//

import SwiftUI


struct KeyboardAdaptive: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    @State private var keyboardAnimationDuration: Double = 0.16

    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onAppear {
                NotificationCenter.default.addObserver(
                    forName: UIResponder.keyboardWillShowNotification,
                    object: nil,
                    queue: .main
                ) { notification in
                    guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
                          let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
                    else { return }
                    
                    // Get the first window from the windowScene
                    let window = UIApplication.shared.connectedScenes
                        .compactMap { $0 as? UIWindowScene }
                        .flatMap { $0.windows }
                        .first
                    
                    let adjustedHeight = keyboardFrame.height - (window?.safeAreaInsets.bottom ?? 0)
                    
                    withAnimation(.easeOut(duration: duration)) {
                        keyboardHeight = adjustedHeight
                        keyboardAnimationDuration = duration
                    }
                }
                
                NotificationCenter.default.addObserver(
                    forName: UIResponder.keyboardWillHideNotification,
                    object: nil,
                    queue: .main
                ) { notification in
                    guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
                    else { return }
                    
                    withAnimation(.easeOut(duration: duration)) {
                        keyboardHeight = 0
                        keyboardAnimationDuration = duration
                    }
                }
            }
    }
}

extension View {
    func keyboardAdaptive() -> some View {
        ModifiedContent(content: self, modifier: KeyboardAdaptive())
    }
}
