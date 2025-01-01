import SwiftUI
import FirebaseAuth
import AuthenticationServices

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isEmailVerified = false
    @Published var showVerificationAlert = false
    @Published var isInitializing = true
    @Published var errorMessage = ""
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    @AppStorage("userAccount") private var userAccount: String = ""

    @Published var isAccountLocked = false

    @AppStorage("failedAttempts") private var failedAttempts: Int = 0
    @AppStorage("lastFailedAttemptTime") private var lastFailedAttemptTime: Double = 0
    private let maxFailedAttempts = 5
    private let lockoutDuration: TimeInterval = 300 // 5 minutes in seconds
    
    init() {
        print("🔐 Initializing AuthenticationViewModel")
        setupAuthStateHandler()
        checkLockoutStatus()
    }
    
    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
    

    private func setupAuthStateHandler() {
        print("🔐 Setting up auth state handler")
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
            print("🔐 Auth state changed - User: \(user?.email ?? "nil")")
            Task {
                await self.validateCurrentUser()
                if self.isInitializing {
                    self.isInitializing = false
                }
            }
        }
    }
    
    @MainActor
    private func validateCurrentUser() async {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ No current user found during validation")
            self.user = nil
            self.isAuthenticated = false
            self.isEmailVerified = false
            return
        }
        
        print("🔄 Validating current user: \(currentUser.email ?? "unknown")")
        do {
            try await currentUser.reload()
            print("✅ User reloaded successfully")
            
            if Auth.auth().currentUser != nil {
                self.user = currentUser
                self.isEmailVerified = currentUser.isEmailVerified
                self.isAuthenticated = currentUser.isEmailVerified
                print("📱 User state updated - Verified: \(currentUser.isEmailVerified)")
            } else {
                print("❌ User was deleted from Firebase")
                self.user = nil
                self.isAuthenticated = false
                self.isEmailVerified = false
                try? Auth.auth().signOut()
            }
        } catch {
            print("❌ Error validating user: \(error.localizedDescription)")
            self.user = nil
            self.isAuthenticated = false
            self.isEmailVerified = false
            self.errorMessage = "Session expired. Please sign in again."
            try? Auth.auth().signOut()
        }
    }
    
    private func checkLockoutStatus() {
        let currentTime = Date().timeIntervalSince1970
        let timeElapsed = currentTime - lastFailedAttemptTime
        
        print("🔒 Checking lockout status - Failed attempts: \(failedAttempts)")
        
        if failedAttempts >= maxFailedAttempts && timeElapsed < lockoutDuration {
            isAccountLocked = true
            let remainingTime = Int(lockoutDuration - timeElapsed)
            errorMessage = "Account is temporarily locked. Please try again in \(remainingTime) seconds."
            print("🔒 Account locked - Remaining time: \(remainingTime)s")
        } else if timeElapsed >= lockoutDuration {
            print("🔓 Lockout period expired - Resetting failed attempts")
            failedAttempts = 0
            isAccountLocked = false
            errorMessage = ""
        }
    }
    
    private func handleFailedAttempt() {
        print("❌ Failed sign-in attempt")
        failedAttempts += 1
        lastFailedAttemptTime = Date().timeIntervalSince1970
        print("🔒 Failed attempts: \(failedAttempts)/\(maxFailedAttempts)")
        checkLockoutStatus()
    }
    
    private func getUserFriendlyError(_ error: Error) -> String {
        let errorMessage = error.localizedDescription
        
        // Firebase Auth error messages
        switch errorMessage {
        case "The supplied auth credential is malformed or has expired.":
            return "Your login session has expired. Please try signing in again."
        case "The email address is badly formatted.":
            return "Please enter a valid email address."
        case "The password is invalid or the user does not have a password.":
            return "Incorrect email or password."
        case "There is no user record corresponding to this identifier. The user may have been deleted.":
            return "No account found with this email."
        case "The email address is already in use by another account.":
            return "An account already exists with this email."
        case "The password must be 6 characters long or more.":
            return "Password must be at least 6 characters long."
        case "Too many unsuccessful login attempts. Please try again later.":
            return "Account temporarily locked due to too many attempts. Please try again later."
        case "Network error (such as timeout, interrupted connection or unreachable host) has occurred.":
            return "Unable to connect. Please check your internet connection."
        default:
            print("⚠️ Unhandled Firebase error: \(errorMessage)")
            return "Unable to sign in. Please try again."
        }
    }
    
    func signIn(email: String, password: String) async throws {
        print("🔐 Attempting sign in for email: \(email)")
        
        checkLockoutStatus()
        
        if isAccountLocked {
            print("🔒 Sign-in blocked - Account is locked")
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        }
        
        do {
            // Ensure clean credentials
            let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
            
            print("🔐 Attempting Firebase sign in with cleaned credentials")
            let result = try await Auth.auth().signIn(withEmail: cleanEmail, password: cleanPassword)
            
            print("✅ Sign in successful for user: \(result.user.email ?? "unknown")")
            userAccount = cleanEmail
            failedAttempts = 0
            
            // Check if email is verified
            if !result.user.isEmailVerified {
                print("⚠️ Email not verified")
                try Auth.auth().signOut()
                throw NSError(domain: "", code: -1, 
                            userInfo: [NSLocalizedDescriptionKey: "Please verify your email before signing in"])
            }
        } catch {
            print("❌ Sign in failed: \(error.localizedDescription)")
            if let err = error as NSError? {
                print("🔍 Error code: \(err.code)")
            }
            handleFailedAttempt()
            throw error
        }
    }
    
    func signUp(email: String, password: String) async throws -> Bool {
        errorMessage = ""
        
        do {
            // Create user but don't set authentication state
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Send verification email
            try await result.user.sendEmailVerification()
            
            // Immediately sign out
            try? Auth.auth().signOut()
            
            // Reset states
            await MainActor.run {
                self.user = nil
                self.isAuthenticated = false
                self.isEmailVerified = false
            }
            return true
        } catch {
            // Handle errors
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            throw error
        }
    }

    
    func resendVerificationEmail() async -> (success: Bool, message: String) {
        guard let currentUser = Auth.auth().currentUser else {
            return (false, "Unable to resend verification email. Please try signing up again.")
        }
        
        do {
            try await currentUser.sendEmailVerification()
            return (true, "Verification email sent successfully")
        } catch {
            handleAuthError(error)
            return (false, errorMessage)
        }
    }
    
    func resetPassword(email: String) async -> (success: Bool, message: String) {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            return (true, "Password reset email sent successfully")
        } catch {
            handleAuthError(error)
            return (false, errorMessage)
        }
    }
    
    func deleteAccount() async -> (success: Bool, message: String) {
        guard let user = Auth.auth().currentUser else {
            return (false, "No user found")
        }
        
        do {
            // Check if user is signed in with Apple
            if user.providerData.contains(where: { $0.providerID == "apple.com" }) {
                // Re-authenticate with Apple
                let (appleIDCredential, error) = await signInWithApple()
                if let error = error {
                    return (false, error.localizedDescription)
                }
                
                guard let appleIDCredential = appleIDCredential,
                      let identityToken = appleIDCredential.identityToken,
                      let tokenString = String(data: identityToken, encoding: .utf8) else {
                    return (false, "Apple Sign In failed")
                }
                
                
                
                // Convert ASAuthorizationAppleIDCredential to AuthCredential
                let credential = OAuthProvider.credential(
                    withProviderID: "apple.com",
                    idToken: tokenString,
                    accessToken: appleIDCredential.authorizationCode != nil ? String(data: appleIDCredential.authorizationCode!, encoding: .utf8) ?? "" : ""
                )
                
                // Re-authenticate
                try await user.reauthenticate(with: credential)
            }
            
            // Now delete the account
            try await user.delete()
            return (true, "Account successfully deleted")
        } catch {
            return (false, error.localizedDescription)
        }
    }
    
    private func signInWithApple() async -> (ASAuthorizationAppleIDCredential?, Error?) {
        return await withCheckedContinuation { continuation in
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.email]
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            let delegate = AppleSignInDelegate { credential, error in
                continuation.resume(returning: (credential, error))
            }
            
            // Hold a reference to the delegate until the completion is called
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
            
            controller.delegate = delegate
            
            // Updated window scene access
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController as? ASAuthorizationControllerPresentationContextProviding {
                controller.presentationContextProvider = rootViewController
            }
            
            controller.performRequests()
        }
    }
    
    // Change email function
    func updateEmail(to newEmail: String) async -> (success: Bool, message: String) {
        guard let user = Auth.auth().currentUser else {
            return (false, "No user found")
        }
        
//        do {
//            try await user.updateEmail(to: newEmail)
//            // Send verification email to new address
//            try await user.sendEmailVerification()
//            return (true, "Email updated successfully. Please verify your new email address.")
//        } catch {
//            return (false, error.localizedDescription)
//        }
        
        do {
            try await user.sendEmailVerification(beforeUpdatingEmail: newEmail)
            return (true, "A verification email has been sent to the new email address. Please verify it to complete the update.")
        } catch {
            handleAuthError(error)
            return (false, errorMessage)
        }

    }
    
    // Change password function
    func updatePassword(to newPassword: String) async -> (success: Bool, message: String) {
        guard let user = Auth.auth().currentUser else {
            return (false, "No user found")
        }
        
        do {
            try await user.updatePassword(to: newPassword)
            return (true, "Password updated successfully")
        } catch {
            return (false, error.localizedDescription)
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.isAuthenticated = false
        } catch {
            handleAuthError(error)
        }
    }

    private func handleAuthError(_ error: Error) {
        errorMessage = error.localizedDescription
    }
}

struct AuthenticationViewModel_Previews: PreviewProvider {
    static var previews: some View {
        Text("")
            .environmentObject(AuthenticationViewModel())
    }
}
