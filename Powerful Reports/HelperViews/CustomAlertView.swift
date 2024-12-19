import SwiftUI

struct CustomAlertView: View {
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                }
            
            VStack(spacing: 0) {
                // Title and Message
                VStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                        .padding(.horizontal, 16)
                    
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                }
                
                Divider()
                    .background(Color.secondary.opacity(0.2))
                
                // Button
                Button(action: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                        action()
                    }
                }) {
                    Text(buttonTitle)
                        .font(.headline)
                        .foregroundColor(.color4)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
            }
            .frame(width: UIScreen.main.bounds.width * 0.72)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(UIColor.systemBackground))
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .transition(.opacity.combined(with: .scale(scale: 1.1)))
    }
}

struct CustomAlertModifier: ViewModifier {
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void
    @Binding var isPresented: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                CustomAlertView(
                    title: title,
                    message: message,
                    buttonTitle: buttonTitle,
                    action: action,
                    isPresented: $isPresented
                )
            }
        }
    }
}

extension View {
    func customAlert(
        title: String,
        message: String,
        buttonTitle: String = "OK",
        isPresented: Binding<Bool>,
        action: @escaping () -> Void = {}
    ) -> some View {
        modifier(CustomAlertModifier(
            title: title,
            message: message,
            buttonTitle: buttonTitle,
            action: action,
            isPresented: isPresented
        ))
    }
}
