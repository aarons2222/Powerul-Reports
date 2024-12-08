import SwiftUI
import FirebaseAuth

struct PasswordResetView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authModel: AuthenticationViewModel
    @State private var email = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    @FocusState private var isEmailFocused: Bool
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    // Background gradient
                    LinearGradient(
                        gradient: Gradient(colors: [.color3.opacity(0.3), .color5.opacity(0.3)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    VStack(spacing: 30) {
                        // Logo and Title
                        VStack(spacing: 20) {
                            Image("logo_clear")
                                .resizable()
                                .frame(width: 120, height: 120)
                                .drawingGroup()
                                .shadow(radius: 10)
                            
                            Text("Reset Password")
                                .font(.system(size: 32, weight: .regular))
                                .foregroundColor(.primary)
                            
                            Text("Enter your email address and we'll send you a link to reset your password")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, geometry.safeAreaInsets.top + 20)
                        
                        // Email field
                        CustomTextField(
                            text: $email,
                            placeholder: "Email",
                            systemImage: "envelope",
                            isSecure: false
                        )
                        .focused($isEmailFocused)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .submitLabel(.send)
                        .onSubmit(handleSubmit)
                        .disabled(isLoading)
                        .padding(.horizontal)
                        
                        // Reset Button
                        Button(action: handleSubmit) {
                            HStack(spacing: 10) {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Send Reset Link")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 45)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [.color2, .color2]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .opacity(isLoading || email.isEmpty ? 0.5 : 1)
                            )
                            .cornerRadius(27)
                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isLoading || email.isEmpty)
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.primary)
                    }
                }
            }
            .overlay {
                if isLoading {
                    LoadingOverlay()
                }
            }
            .alert(isSuccess ? "Success" : "Error", isPresented: $showAlert) {
                Button("OK") {
                    if isSuccess {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func handleSubmit() {
        let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !emailTrimmed.isEmpty else { return }
        
        isLoading = true
        isEmailFocused = false
        
        Task {
            let (success, message) = await authModel.resetPassword(email: emailTrimmed)
            await MainActor.run {
                isSuccess = success
                alertMessage = message
                showAlert = true
                isLoading = false
            }
        }
    }
}

#Preview {
    PasswordResetView()
        .environmentObject(AuthenticationViewModel())
}
