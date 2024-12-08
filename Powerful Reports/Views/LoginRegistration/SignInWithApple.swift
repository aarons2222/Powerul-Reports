//
//  SignInWithApple.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 08/12/2024.
//


import SwiftUI
import AuthenticationServices
import Firebase
import FirebaseAuth
import CryptoKit


struct SignInWithApple: View {
    @EnvironmentObject var authModel: AuthenticationViewModel
    @State private var showAlert: Bool = false
    @State private var isLoading: Bool = false
    @State private var nonce: String?
    @State private var errorMessage: String = ""
    @State private var navigateToLogin: Bool = false
    @State private var navigateToPolicy: Bool = false
    @State private var isAnimating = false
    
    @State private var chosenPolicy: PolicyType = .privacy
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Background gradient
                    LinearGradient(
                        gradient: Gradient(colors: [.color3.opacity(0.3), .color5.opacity(0.3)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    VStack {
                        
                        
                        VStack(spacing: 20) {
                            Image("logo_clear")
                                .resizable()
                                .frame(width: 120, height: 120)
                                .drawingGroup()
                                .shadow(radius: 10)
                                .opacity(isAnimating ? 1 : 0)
                                .offset(y: isAnimating ? 0 : -20)
                         
                            
                            Text("Welcome, please choose an option below to get started ")
                                .font(.system(size: 30, weight: .regular))
                                .foregroundColor(.primary)
                                .opacity(isAnimating ? 1 : 0)
                                .offset(y: isAnimating ? 0 : 20)
                           
                        }
                        .padding(.top, geometry.safeAreaInsets.top + 100)
                        Spacer()
                        
                        VStack(spacing: 0){
                            // Sign in with Apple Button
                            SignInWithAppleButton(.signIn) { request in
                                let nonce = randomNonceString()
                                self.nonce = nonce
                                /// Your Preferences
                                request.requestedScopes = [.email, .fullName]
                                request.nonce = sha256(nonce)
                            } onCompletion: { result in
                                isLoading = true
                                switch result {
                                case .success(let authorization):
                                    loginWithFirebase(authorization)
                                case .failure(let error):
                                    isLoading = false
                                    showError(error.localizedDescription)
                                }
                            }
                            .overlay {
                                ZStack {
                                    Capsule()
                                    
                                    HStack {
                                        Image(systemName: "applelogo")
                                        
                                        Text("Sign in with Apple")
                                    }
                                    .foregroundStyle(.white)
                                }
                                .allowsHitTesting(false)
                            }
                            .frame(height: 50)
                            .clipShape(.capsule)
                            .padding(.vertical, 10)
                            
                            GlobalButton(title: "Sign in with email") {
                                navigateToLogin = true
                            }
                            
                            HStack(spacing: 5) {
                            
                                
                                Button{
                                    self.chosenPolicy = .terms
                                    navigateToPolicy.toggle()
                                }label: {
                                    Text("Terms of Serivce")
                                }
                                Text(" | ")
                                
                                Button{
                                    self.chosenPolicy = .privacy
                                    navigateToPolicy.toggle()
                                }label: {
                                    Text("Privacy Policy")
                                }
                                
                            }
                            .foregroundColor(.color2.opacity(0.8))
                            .font(.subheadline)
                            .padding(.top, 10)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .ignoresSafeArea()
            .navigationDestination(isPresented: $navigateToLogin) {
                LoginRegView()
            }
            .navigationDestination(isPresented: $navigateToPolicy) {
                PolicyView(policy: chosenPolicy)
            }
            .alert("Error", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    isAnimating = true
                }
            }
            .overlay(content: {
                if isLoading {
                    LoadingOverlay(message: "Signing In")
                }
            })
        }
     
    }

            
            
            func showError(_ message: String) {
                errorMessage = message
                showAlert.toggle()
                isLoading = false
            }
            
            /// Login With Firebase
            private func loginWithFirebase(_ authorization: ASAuthorization) {
                if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                    guard let nonce = self.nonce else {
                        showError("Invalid state: A login callback was received, but no login request was sent.")
                        isLoading = false
                        return
                    }
                    
                    guard let appleIDToken = appleIDCredential.identityToken else {
                        showError("Unable to fetch identity token")
                        isLoading = false
                        return
                    }
                    
                    guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                        showError("Unable to serialize token string from data")
                        isLoading = false
                        return
                    }
                    
                    let credential = OAuthProvider.credential(
                        withProviderID: "apple.com",
                        idToken: idTokenString,
                        rawNonce: nonce
                    )
                    
                    Task {
                        do {
                            let result = try await Auth.auth().signIn(with: credential)
                            await MainActor.run {
                                authModel.user = result.user
                                authModel.isAuthenticated = true
                                isLoading = false
                                
                            }
                        } catch {
                            await MainActor.run {
                                showError(error.localizedDescription)
                                isLoading = false
                            }
                        }
                    }
                }
            }
       
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        
        let charset: Array<Character> = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        
        let nonce = randomBytes.map { byte in
            // Pick a random character from the charset
            charset[Int(byte) % charset.count]
        }
        
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

#Preview {
    SignInWithApple()
}
