import SwiftUI
import FirebaseAuth

struct EmailPasswordSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authModel: AuthenticationViewModel
    
    @State private var newEmail = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Email")) {
                    TextField("New Email", text: $newEmail)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    
                    Button("Update Email") {
                        updateEmail()
                    }
                    .disabled(newEmail.isEmpty)
                }
                
                Section(header: Text("Password")) {
                    SecureField("New Password", text: $newPassword)
                        .textContentType(.newPassword)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                    
                    Button("Update Password") {
                        updatePassword()
                    }
                    .disabled(newPassword.isEmpty || confirmPassword.isEmpty || newPassword != confirmPassword)
                }
            }
            .navigationTitle("Email & Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            ProgressView()
                                .tint(.white)
                        }
                }
            }
        }
    }
    
    private func updateEmail() {
        guard !newEmail.isEmpty else { return }
        isLoading = true
        
        Task {
            let result = await authModel.updateEmail(to: newEmail)
            await MainActor.run {
                isLoading = false
                alertTitle = result.success ? "Success" : "Error"
                alertMessage = result.message
                showAlert = true
                if result.success {
                    newEmail = ""
                }
            }
        }
    }
    
    private func updatePassword() {
        guard !newPassword.isEmpty, newPassword == confirmPassword else { return }
        isLoading = true
        
        Task {
            let result = await authModel.updatePassword(to: newPassword)
            await MainActor.run {
                isLoading = false
                alertTitle = result.success ? "Success" : "Error"
                alertMessage = result.message
                showAlert = true
                if result.success {
                    newPassword = ""
                    confirmPassword = ""
                }
            }
        }
    }
}

#Preview {
    EmailPasswordSettingsView()
}
