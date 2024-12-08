import SwiftUI
import FirebaseAuth
import AuthenticationServices

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var isEmailVerified = false
    @Published var showVerificationAlert = false
    @Published var isInitializing = true
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    @AppStorage("userAccount") private var userAccount: String = ""

    @Published var isAccountLocked = false

    @AppStorage("failedAttempts") private var failedAttempts: Int = 0
    @AppStorage("lastFailedAttemptTime") private var lastFailedAttemptTime: Double = 0
    private let maxFailedAttempts = 5
    private let lockoutDuration: TimeInterval = 300 // 5 minutes in seconds
    
    init() {
        setupAuthStateHandler()
        checkLockoutStatus()
    }
    
    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
    

    private func setupAuthStateHandler() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            
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
            self.user = nil
            self.isAuthenticated = false
            self.isEmailVerified = false
            return
        }
        
        do {
            // Reload the user to get the latest state
            try await currentUser.reload()
            
            // Check if user still exists and is verified
            if Auth.auth().currentUser != nil {
                self.user = currentUser
                self.isEmailVerified = currentUser.isEmailVerified
                self.isAuthenticated = currentUser.isEmailVerified
            } else {
                // User was deleted from Firebase
                self.user = nil
                self.isAuthenticated = false
                self.isEmailVerified = false
                try? Auth.auth().signOut()
            }
        } catch {
            // Handle error (user might have been deleted)
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
        
        if failedAttempts >= maxFailedAttempts && timeElapsed < lockoutDuration {
            isAccountLocked = true
            let remainingTime = Int(lockoutDuration - timeElapsed)
            errorMessage = "Account is temporarily locked. Please try again in \(remainingTime) seconds."
        } else if timeElapsed >= lockoutDuration {
            // Reset failed attempts after lockout period
            failedAttempts = 0
            isAccountLocked = false
            errorMessage = ""
        }
    }
    
    private func handleFailedAttempt() {
        failedAttempts += 1
        lastFailedAttemptTime = Date().timeIntervalSince1970
        
        if failedAttempts >= maxFailedAttempts {
            isAccountLocked = true
            errorMessage = "Too many failed attempts. Account is locked for 5 minutes."
        } else {
            let remainingAttempts = maxFailedAttempts - failedAttempts
            errorMessage = "Invalid credentials. \(remainingAttempts) attempts remaining."
        }
    }
    
    
    func signIn(email: String, password: String) {
         isLoading = true
         
         // Check for account lockout
         checkLockoutStatus()
         if isAccountLocked {
             isLoading = false
             return
         }
         
         Task {
             do {
                 let result = try await Auth.auth().signIn(withEmail: email, password: password)
                 
                 if !result.user.isEmailVerified {
                     // For unverified users, show verification alert and sign out
                     try Auth.auth().signOut()
                     
                     await MainActor.run {
                         self.errorMessage = "Please verify your email before signing in"
                         self.user = nil
                         self.isAuthenticated = false
                         self.isEmailVerified = false
                         self.isLoading = false
                         self.showVerificationAlert = true
                     }
                     return
                 }
                 
                 // Successful login - reset failed attempts
                 await MainActor.run {
                     self.failedAttempts = 0
                     self.user = result.user
                     self.isAuthenticated = true
                     self.isEmailVerified = true
                     self.isLoading = false
                     self.errorMessage = ""
                 }
             } catch {
                 await MainActor.run {
                     handleFailedAttempt()
                     handleAuthError(error)
                     self.isLoading = false
                 }
             }
         }
     }
    
    func signUp(email: String, password: String) {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                // Create user but don't set authentication state
                let result = try await Auth.auth().createUser(withEmail: email, password: password)
                
                // Send verification email
                try await result.user.sendEmailVerification()
                
                // Immediately sign out
                try Auth.auth().signOut()
                
                await MainActor.run {
                    // Show verification alert
                    self.showVerificationAlert = true
                    
                    // Reset states
                    self.user = nil
                    self.isAuthenticated = false
                    self.isEmailVerified = false
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    handleAuthError(error)
                    self.isLoading = false
                }
            }
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
        
        let appleProvider = user.providerData.first { $0.providerID == "apple.com" }

        
        do {
      
               
               if appleProvider != nil {
                   // For Apple Sign In users, we'll skip the credential check and revocation
                   // as Firebase will handle the cleanup on their end
                   print("User signed in with Apple, proceeding with account deletion")
               }
               
                   
            // Delete the Firebase account
            try await user.delete()
            
            await MainActor.run {
                self.user = nil
                self.isAuthenticated = false
                self.isEmailVerified = false
                self.userAccount = ""
            }
            
            return (true, "Account deleted successfully")
        } catch let error as ASAuthorizationError {
            // Handle Apple Sign In specific errors
            switch error.code {
            case .canceled:
                return (false, "Apple ID revocation was canceled")
            case .failed:
                return (false, "Failed to revoke Apple ID. Please try again")
            case .invalidResponse:
                return (false, "Invalid response while revoking Apple ID")
            case .notHandled:
                return (false, "Apple ID revocation not handled")
            default:
                return (false, "Error revoking Apple ID: \(error.localizedDescription)")
            }
        } catch {
            handleAuthError(error)
            return (false, errorMessage)
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
        let err = error as NSError
        if let authError = AuthErrorCode(_bridgedNSError: err) {
            switch authError.code {
            case .wrongPassword:
                self.errorMessage = "Incorrect password. Please try again."
            case .invalidEmail:
                self.errorMessage = "Invalid email format."
            case .emailAlreadyInUse:
                self.errorMessage = "This email is already registered."
            case .weakPassword:
                self.errorMessage = "Password is too weak. Please use at least 8 characters."
            case .userNotFound:
                self.errorMessage = "No account found with this email."
            case .networkError:
                self.errorMessage = "Network error. Please check your connection."
            default:
                self.errorMessage = error.localizedDescription
            }
        } else {
            self.errorMessage = error.localizedDescription
        }
    }
}
