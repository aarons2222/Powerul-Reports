import SwiftUI


struct LoadingOverlay: View {
    let message: String
    let blurRadius: CGFloat
    
    init(message: String = "Loading...", blurRadius: CGFloat = 3) {
        self.message = message
        self.blurRadius = blurRadius
    }
    
    var body: some View {
        ZStack {
            // Background blur effect
            Rectangle()
                
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.2)
                    .tint(.white)
                
                Text(message)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: 150)
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
            }
            .transition(.opacity.combined(with: .scale))
        }
    }
}

// Modern Preview using ViewThat modifier
#Preview("Loading Overlay") {
    ZStack {
        // Sample background content
        LinearGradient(
            colors: [.blue, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        LoadingOverlay(message: "Please wait...")
    }
}

