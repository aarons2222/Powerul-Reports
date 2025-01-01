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

struct PasswordRequirement: Identifiable {
    let id = UUID()
    let text: String
    var isMet: Bool
}

struct PasswordRequirementRow: View {
    let requirement: PasswordRequirement
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: requirement.isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(requirement.isMet ? .color2 : .gray)
            Text(requirement.text)
                .font(.caption)
                .foregroundColor(requirement.isMet ? .primary : .gray)
        }
    }
}

struct LoginRegView: View {
    @Environment(\.presentationMode) var presentationMode

    @EnvironmentObject var authModel: AuthenticationViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSignUp = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var showResetAlert = false
    @State private var showPasswordReset = false
    @State private var resetMessage = ""
    @State private var resetSuccess = false
    @FocusState private var focusedField: Field?
    @State private var keyboardHeight: CGFloat = 0
    
    @State private var errorMessage: String = ""
    @State private var showToast: Bool = false
    @State private var showVerificationToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var passwordRequirements: [PasswordRequirement] = [
        PasswordRequirement(text: "At least 8 characters", isMet: false),
        PasswordRequirement(text: "Contains a number", isMet: false),
        PasswordRequirement(text: "Contains a special character", isMet: false),
        PasswordRequirement(text: "Passwords match", isMet: false)
    ]
  
    private var passwordValidation: (isValid: Bool, message: String) {
        updatePasswordRequirements()
        return (passwordRequirements.allSatisfy { $0.isMet }, "")
    }
    
    private func updatePasswordRequirements() {
        let password = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Update each requirement
        passwordRequirements[0].isMet = password.count >= 8
        passwordRequirements[1].isMet = password.contains(where: { $0.isNumber })
        passwordRequirements[2].isMet = password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) })
        passwordRequirements[3].isMet = !isSignUp || password == confirmPassword && password.count >= 8 
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [.color3.opacity(0.3), .color5.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    HStack {
                        Button {
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            Image(systemName: "chevron.backward.circle.fill")
                                .font(.title)
                                .fontWeight(.regular)
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(.leading)
                        }
                        Spacer()
                    }
                    
                    Spacer(minLength: 40)
                    
                    // Logo and Title
                    VStack(spacing: 20) {
                        Image("logo_clear")
                            .resizable()
                            .frame(width: 120, height: 120)
                            .drawingGroup()
                            .shadow(radius: 10)
                        
                        Text(isSignUp ? "Create Account" : "Welcome Back")
                            .font(.system(size: 32, weight: .regular))
                            .foregroundColor(.primary)
                            .animation(.easeInOut(duration: 0.3), value: isSignUp)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.95)).animation(.easeInOut(duration: 0.3)),
                                removal: .opacity.combined(with: .scale(scale: 1.05)).animation(.easeInOut(duration: 0.3))
                            ))
                            .id(isSignUp)
                    }
                    .offset(y: isSignUp ? -40 : 0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.9), value: isSignUp)
                    
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
                        .disabled(false)
                        .offset(y: isSignUp ? -30 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.9).delay(0.05), value: isSignUp)
                        
                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            CustomSecureField(
                                text: $password,
                                placeholder: "Password",
                                showPassword: $showPassword,
                                focusedField: $focusedField,
                                field: .password,
                                onSubmit: {
                                    if isSignUp {
                                        focusedField = .confirmPassword
                                    } else {
                                        handleSignIn()
                                    }
                                }
                            )
                            .onChange(of: password) {
                                updatePasswordRequirements()
                            }
                            .offset(y: isSignUp ? -20 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.9).delay(0.1), value: isSignUp)
                            
                            if isSignUp {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(passwordRequirements) { requirement in
                                        PasswordRequirementRow(requirement: requirement)
                                    }
                                }
                                .padding(.horizontal, 4)
                                .padding(.bottom, 8)
                                .animation(.easeInOut, value: password)
                            }
                        }
                        
                        if isSignUp {
                            // Confirm Password field
                            CustomTextField(
                                text: $confirmPassword,
                                placeholder: "Confirm Password",
                                systemImage: "lock",
                                isSecure: showConfirmPassword,
                                showSecureToggle: true,
                                onToggleSecure: { showConfirmPassword.toggle() }
                            )
                            .focused($focusedField, equals: .confirmPassword)
                            .submitLabel(.go)
                            .onSubmit(handleSignUp)
                            .disabled(false)
                            .onChange(of: confirmPassword) { 
                                updatePasswordRequirements()
                            }
                            .offset(y: isSignUp ? -10 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.9).delay(0.15), value: isSignUp)
                        } else {
                            // Forgot Password Link (only show in sign-in mode)
                            HStack {
                                Spacer()
                                Button(action: { showPasswordReset = true }) {
                                    Text("Forgot Password?")
                                        .foregroundColor(.color2.opacity(0.8))
                                        .font(.subheadline)
                                }
                                .disabled(false)
                            }
                            .padding(.top, -8)
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
               
                    
                    Spacer()
                    
                    VStack(spacing: 16) {
                     
                        
                        GlobalButton(title: isSignUp ? "Sign Up" : "Sign In"){
                            if (isSignUp){
                                handleSignUp()
                            }else{
                                handleSignIn()
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: isSignUp)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)).animation(.easeInOut(duration: 0.3)),
                            removal: .opacity.combined(with: .scale(scale: 1.05)).animation(.easeInOut(duration: 0.3))
                        ))
                        .id(isSignUp) // Forces view replacement for transition
                        
                        
                        
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
                        .disabled(false)
                    }
        
                }
                .padding(.horizontal, 20)
                .padding(.bottom, keyboardHeight + 20)
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .offset(y: -keyboardHeight/2)
        .animation(.easeOut(duration: 0.16), value: keyboardHeight)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationBarHidden(true)
        .onChange(of: authModel.isAuthenticated) { newValue in
            if authModel.isAuthenticated {
                focusedField = nil
            }
        }
        .alert("Password Reset", isPresented: $showResetAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(resetMessage)
        }
        .alert("Email Verification", isPresented: $authModel.showVerificationAlert) {
            Button("OK") {
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
        .toast(isPresented: $showToast, message: toastMessage)
        .toast(isPresented: $showVerificationToast, message: toastMessage, isError: false, duration: 3.0)
    }
    
    private func handleSignIn() {
        let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let passwordTrimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !emailTrimmed.isEmpty else {
            toastMessage = "Please enter your email"
            withAnimation {
                showToast = true
            }
            return
        }
        
        guard !passwordTrimmed.isEmpty else {
            toastMessage = "Please enter your password"
            withAnimation {
                showToast = true
            }
            return
        }
        
        Task {
            do {
                try await authModel.signIn(email: emailTrimmed, password: passwordTrimmed)
            } catch {
                if let err = error as NSError? {
                    // Check for specific Firebase error codes
                    switch err.code {
                    case AuthErrorCode.wrongPassword.rawValue:
                        toastMessage = "Incorrect email or password"
                    case AuthErrorCode.invalidEmail.rawValue:
                        toastMessage = "Please enter a valid email address"
                    case AuthErrorCode.userNotFound.rawValue:
                        toastMessage = "No account found with this email"
                    default:
                        toastMessage = "Unable to sign in. Please try again."
                    }
                } else {
                    toastMessage = "Unable to sign in. Please try again."
                }
                withAnimation {
                    showToast = true
                }
            }
        }
    }
    
    private func handleSignUp() {
        Task{
            let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Validate email
            if emailTrimmed.isEmpty {
                errorMessage = "Email is required"
                return
            }
            
            // Validate password
            let validation = passwordValidation
            if !validation.isValid {
                errorMessage = validation.message
                return
            }
            
            let success = await authModel.signUp(email: email, password: password)
            
            if success {
                toastMessage = "Verification code sent to \(email)"
                withAnimation {
                    showVerificationToast = true
                }
            }
        }
    }
    

    
    private func handleResetPassword() {
        let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if emailTrimmed.isEmpty {
            errorMessage = "Please enter your email address"
            return
        }
        
        Task {
            let (success, message) = await authModel.resetPassword(email: emailTrimmed)
            await MainActor.run {
                resetSuccess = success
                resetMessage = message
                showResetAlert = true
            }
        }
    }
    
    private func handleResendVerification() {
        Task {
            let (success, message) = await authModel.resendVerificationEmail()
            await MainActor.run {
                if success {
                    resetMessage = "Verification email sent successfully. Please check your inbox."
                } else {
                    resetMessage = message
                }
                showResetAlert = true
                
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
                 authModel.signOut()
            }
        }
    }
}

struct CustomTextField: View {
    let text: Binding<String>
    let placeholder: String
    let systemImage: String
    var isSecure: Bool = false
    var showSecureToggle: Bool = false
    var onToggleSecure: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundColor(.color1)

            if isSecure {
                SecureField(placeholder, text: text)
                    .textContentType(.none)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            } else {
                TextField(placeholder, text: text)
                    .textContentType(.none)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }

            if showSecureToggle {
                Button(action: {
                    onToggleSecure?()
                }) {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 13)
        .background(
           Capsule()
                .fill(Color.gray.opacity(0.1))
                .stroke(.color2, lineWidth: 2)
        )
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct CustomSecureField: View {
    let text: Binding<String>
    let placeholder: String
    let showPassword: Binding<Bool>
    let focusedField: FocusState<Field?>.Binding
    let field: Field
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "lock")
                .foregroundColor(.color1)
            

            Group {
                if showPassword.wrappedValue {
                    TextField(placeholder, text: text)
                        .textContentType(.none)
                        .focused(focusedField, equals: field)
                } else {
                    SecureField(placeholder, text: text)
                        .textContentType(.none)
                        .focused(focusedField, equals: field)
                }
            }
            .submitLabel(.next)
            .onSubmit(onSubmit)
            .autocapitalization(.none)
            .disableAutocorrection(true)

            Button(action: {
                showPassword.wrappedValue.toggle()
            }) {
                Image(systemName: showPassword.wrappedValue ? "eye.slash" : "eye")
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 13)
        .background(
           Capsule()
                .fill(Color.gray.opacity(0.1))
                .stroke(.color2, lineWidth: 2)
        )
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

#Preview {
    LoginRegView()
        .environmentObject(AuthenticationViewModel())
}
