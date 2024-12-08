//
//  LoginReg.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 04/12/2024.
//

import SwiftUI
import AuthenticationServices
import Firebase
import FirebaseAuth
import CryptoKit

enum Field: Hashable {
    case email, password, confirmPassword
}

struct LoginRegView: View {
    @EnvironmentObject var authModel: AuthenticationViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignUp = false
    @State private var isAnimating = false
    @State private var isLoading = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var showResetAlert = false
    @State private var showPasswordReset = false
    @State private var resetMessage = ""
    @State private var resetSuccess = false
    @State private var rememberMe = false
    @FocusState private var focusedField: Field?
    
    @State private var errorMessage: String = ""
  
    private var passwordValidation: (isValid: Bool, message: String) {
        let password = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if password.isEmpty {
            return (false, "Password is required")
        }
        if password.count < 8 {
            return (false, "Password must be at least 8 characters")
        }
        if !password.contains(where: { $0.isNumber }) {
            return (false, "Password must contain at least 1 number")
        }
        if !password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) }) {
            return (false, "Password must contain at least 1 special character")
        }
        if isSignUp && password != confirmPassword {
            return (false, "Passwords do not match")
        }
        return (true, "")
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [.color3.opacity(0.3), .color5.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        // Logo and Title
                        VStack(spacing: 20) {
                            Image("logo_clear")
                                .resizable()
                                .frame(width: 120, height: 120)
                                .drawingGroup()
                                .shadow(radius: 10)
                                .opacity(isAnimating ? 1 : 0)
                                .offset(y: isAnimating ? 0 : -20)
                            
                            Text(isSignUp ? "Create Account" : "Welcome Back")
                                .font(.system(size: 32, weight: .regular))
                                .foregroundColor(.primary)
                                .opacity(isAnimating ? 1 : 0)
                                .offset(y: isAnimating ? 0 : 20)
                        }
                   
                        
                        // Form fields
                        VStack(spacing: 20) {
                            // Email field
                            CustomTextField(
                                text: $email,
                                placeholder: "Email",
                                systemImage: "envelope",
                                isSecure: false
                            )
                            .focused($focusedField, equals: .email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .password
                            }
                            .disabled(isLoading)
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 4) {
                                CustomSecureField(
                                    text: $password,
                                    placeholder: "Password",
                                    showPassword: $showPassword,
                                    focusedField: _focusedField,
                                    field: .password,
                                    onSubmit: {
                                        if isSignUp {
                                            focusedField = .confirmPassword
                                        } else {
                                            handleSignIn()
                                        }
                                    }
                                )
                                
                                if !password.isEmpty && !passwordValidation.isValid {
                                    Text(passwordValidation.message)
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                            }
                            
                            if isSignUp {
                                // Confirm Password field
                                VStack(alignment: .leading, spacing: 4) {
                                    CustomTextField(
                                        text: $confirmPassword,
                                        placeholder: "Confirm Password",
                                        systemImage: "lock",
                                        isSecure: !showConfirmPassword,
                                        showSecureToggle: true,
                                        onToggleSecure: { showConfirmPassword.toggle() }
                                    )
                                    .focused($focusedField, equals: .confirmPassword)
                                    .submitLabel(.go)
                                    .onSubmit(handleSignUp)
                                    .disabled(isLoading)
                                    
                                    if !confirmPassword.isEmpty && password != confirmPassword {
                                        Text("Passwords do not match")
                                            .foregroundColor(.red)
                                            .font(.caption)
                                    }
                                }
                            } else {
                                // Forgot Password Link (only show in sign-in mode)
                                HStack {
                                    Spacer()
                                    Button(action: { showPasswordReset = true }) {
                                        Text("Forgot Password?")
                                            .foregroundColor(.color2.opacity(0.8))
                                            .font(.subheadline)
                                    }
                                    .disabled(isLoading)
                                }
                                .padding(.top, -8)
                                
                                Toggle(isOn: $rememberMe) {
                                    Text("Remember me")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                            }
                            
                            // Error message
                            if !authModel.errorMessage.isEmpty {
                                Text(authModel.errorMessage)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .padding(.horizontal)
                                    .transition(.opacity)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                        
                        VStack(spacing: 16) {
                 
                            
                            // Sign In/Sign Up Button
                            Button(action: isSignUp ? handleSignUp : handleSignIn) {
                                HStack(spacing: 10) {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text(isSignUp ? "Sign Up" : "Sign In")
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
                                    .opacity(isLoading || !isValidInput ? 0.5 : 1)
                                )
                                .cornerRadius(27)
                                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .disabled(isLoading || !isValidInput)
                            
                            // Toggle between Sign Up and Sign In
                            Button(action: {
                                withAnimation {
                                    isSignUp.toggle()
                                    email = ""
                                    password = ""
                                    confirmPassword = ""
                                    errorMessage = ""
                                    focusedField = nil
                                }
                            }) {
                                HStack(spacing: 5) {
                                    Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                        .foregroundColor(.primary.opacity(0.8))
                                        .font(.subheadline)
                                    
                                    if !isSignUp {
                                        Text("Sign Up")
                                            .foregroundColor(.color2.opacity(0.8))
                                            .font(.subheadline)
                                    } else {
                                        Text("Sign In")
                                            .foregroundColor(.color2.opacity(0.8))
                                            .font(.subheadline)
                                    }
                                }
                            }
                            .disabled(isLoading)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
  
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
            
            // Try to load saved credentials
            if !isSignUp {
                do {
                    let credentials = try KeychainManager.shared.retrieveCredentials()
                    email = credentials.email
                    password = credentials.password
                    rememberMe = true
                } catch {
                    // No saved credentials or error occurred
                    print("No saved credentials found")
                }
            }
        }
        .onChange(of: authModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                focusedField = nil
            }
        }
        .onChange(of: authModel.errorMessage) { newValue in
            if !newValue.isEmpty {
                isLoading = false
            }
        }
        .overlay(content: {
            if isLoading {
                LoadingOverlay()
            }
        })
        .alert("Password Reset", isPresented: $showResetAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(resetMessage)
        }
        .alert("Email Verification", isPresented: $authModel.showVerificationAlert) {
            Button("OK") {
                isLoading = false

                email = ""
                password = ""
                confirmPassword = ""
                errorMessage = ""
                isSignUp = false
            }
            Button("Resend Email") {
                handleResendVerification()
            }
        } message: {
            Text(isSignUp ? 
                 "We've sent a verification email to \(email). Please verify your email address before signing in." :
                 "This account needs to be verified. Would you like us to send another verification email?")
        }
        .sheet(isPresented: $showPasswordReset) {
            PasswordResetView()
        }
    }
    
    private var isValidInput: Bool {
        let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return !emailTrimmed.isEmpty && passwordValidation.isValid
    }
    
    private func handleSignIn() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                // First try to sign in
                try await authModel.signIn(email: email, password: password)
                
                // If sign in is successful and remember me is enabled, save credentials
                if rememberMe {
                    do {
                        try KeychainManager.shared.saveCredentials(email: email, password: password)
                    } catch {
                        print("Failed to save credentials: \(error)")
                    }
                } else {
                    // If remember me is not enabled, ensure no credentials are saved
                    try? KeychainManager.shared.deleteCredentials()
                }
                
                isLoading = false
            } catch {
                // If sign in fails, clear any saved credentials
                try? KeychainManager.shared.deleteCredentials()
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func handleSignUp() {
        isLoading = true
        errorMessage = "" // Clear any previous error
        authModel.signUp(email: email, password: password)
    }
    
    private func handleResetPassword() {
        let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if emailTrimmed.isEmpty {
            errorMessage = "Please enter your email address"
            return
        }
        
        isLoading = true
        Task {
            let (success, message) = await authModel.resetPassword(email: emailTrimmed)
            await MainActor.run {
                resetSuccess = success
                resetMessage = message
                showResetAlert = true
                isLoading = false
            }
        }
    }
    
    private func handleResendVerification() {
        isLoading = true
        Task {
            let (success, message) = await authModel.resendVerificationEmail()
            await MainActor.run {
                if success {
                    resetMessage = "Verification email sent successfully. Please check your inbox."
                } else {
                    resetMessage = message
                }
                showResetAlert = true
                isLoading = false
                
                // Clear form after resending verification
                email = ""
                password = ""
                confirmPassword = ""
                errorMessage = ""
            }
        }
    }
    
    private func handleSignOut() {
        Task {
            do {
                try await authModel.signOut()
                // Always clear saved credentials when signing out
                try? KeychainManager.shared.deleteCredentials()
                rememberMe = false
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct CustomTextField: View {
    let text: Binding<String>
    let placeholder: String
    let systemImage: String
    let isSecure: Bool
    var showSecureToggle: Bool = false
    var onToggleSecure: (() -> Void)? = nil
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.secondary)
            
            ZStack(alignment: .trailing) {
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                }
                
                if showSecureToggle {
                    Button(action: { onToggleSecure?() }) {
                        Image(systemName: isSecure ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(.secondary)
                    }
                    .padding(.trailing, 8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct CustomSecureField: View {
    let text: Binding<String>
    let placeholder: String
    @Binding var showPassword: Bool
    @FocusState var focusedField: Field?
    let field: Field
    let onSubmit: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "lock")
                .foregroundColor(.secondary)
            
            ZStack(alignment: .trailing) {
                if showPassword {
                    TextField(placeholder, text: text)
                        .submitLabel(.next)
                        .onSubmit(onSubmit)
                } else {
                    SecureField(placeholder, text: text)
                        .submitLabel(.next)
                        .onSubmit(onSubmit)
                }
                
                Button(action: { showPassword.toggle() }) {
                    Image(systemName: showPassword ? "eye.fill" : "eye.slash.fill")
                        .foregroundColor(.secondary)
                }
                .padding(.trailing, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .focused($focusedField, equals: field)
    }
}

#Preview {
    LoginRegView()
        .environmentObject(AuthenticationViewModel())
}
