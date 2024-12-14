import SwiftUI

struct ToastView: View {
    let message: String
    let isError: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .foregroundColor(isError ? .white : .white)
                .font(.headline)
            
            Text(message)
                .font(.callout)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Capsule()
                .fill(isError ? Color.color8 : Color.color2.opacity(0.9))
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        )
    }
}

struct ToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let isError: Bool
    let duration: TimeInterval
    @State private var offset: CGFloat = -150
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if isPresented {
                ToastView(message: message, isError: isError)
                    .padding(.horizontal)
                    .padding(.vertical, 0)
                    .offset(y: offset)
                    .onAppear {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            offset = 0
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                offset = -150
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isPresented = false
                                offset = -150  // Reset for next time
                            }
                        }
                    }
            }
        }
        .padding(0)
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String, isError: Bool = true, duration: TimeInterval = 3) -> some View {
        modifier(ToastModifier(isPresented: isPresented, message: message, isError: isError, duration: duration))
    }
}
