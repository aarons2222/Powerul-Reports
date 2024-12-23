//
//  AccountView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 10/12/2024.
//

import SwiftUI
import FirebaseAuth

struct AccountView: View {
    @EnvironmentObject var authModel: AuthenticationViewModel
    @State var subscriptionModel = SubscriptionStatusModel()
    @State private var showSignOutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showDeleteConfirmation = false
    @State private var showEmailPasswordSettings = false
    
    
    
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
  
    
    private func formatMemberDuration(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .day, .hour], from: date, to: now)
        
        if let years = components.year, years > 0 {
            if let days = components.day, days > 0 {
                return "\(years) Years \(days) Days"
            }
            return "\(years) Years"
        }
        
        if let days = components.day, days > 0 {
            return "\(days) Days"
        }
        
        if let hours = components.hour {
            return "\(hours) Hours"
        }
        
        return "Just joined"
    }
    
    
    var deleteAccountMessage: String {
        if let user = authModel.user,
           user.providerData.first(where: { $0.providerID == "apple.com" }) != nil {
            return "This will permanently delete your account and revoke the associated Apple ID credentials. This action CANNOT be undone. Are you absolutely sure?"
        }
        return "This will permanently delete your account and all associated data. This action CANNOT be undone. Are you absolutely sure?"
    }
    
    // Helper functions for sign-in method display
    private func getSignInMethodIcon(for user: User) -> String {
        if user.providerData.contains(where: { $0.providerID == "apple.com" }) {
            return "applelogo"
        } else if user.providerData.contains(where: { $0.providerID == "google.com" }) {
            return "g.circle.fill"
        } else if user.providerData.contains(where: { $0.providerID == "password" }) {
            return "envelope.fill"
        }
        return "person.fill"
    }
    
    private func getSignInMethodText(for user: User) -> String {
        if user.providerData.contains(where: { $0.providerID == "apple.com" }) {
            return "Signed in with Apple"
        } else if user.providerData.contains(where: { $0.providerID == "google.com" }) {
            return "Signed in with Google"
        } else if user.providerData.contains(where: { $0.providerID == "password" }) {
            return "Signed in with Email"
        }
        return "Unknown sign-in method"
    }
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            CustomHeaderVIew(title: "Account")
            Spacer()
            
            
            
            
            
            
            
            // Bottom Actions
            VStack(spacing: 25) {
                
                
                if let user = authModel.user {
                    HStack(spacing: 24) {
                        // Avatar
                        Circle()
                            .fill(Color.color2.opacity(0.15))
                            .frame(width: 58, height: 58)
                            .overlay(
                                Text((user.email?.prefix(1).uppercased() ?? "?"))
                                    .font(.title2.weight(.semibold))
                                    .foregroundColor(.color2)
                            )
                            .shadow(color: .color2.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        // User Info
                        VStack(alignment: .leading, spacing: 6) {
                            Text(user.email ?? "No email")
                                .font(.subheadline)
                                .fontWeight(.regular)
                                .foregroundColor(.color4)
                            
                            if let creationDate = user.metadata.creationDate {
                                Text("Member for \(formatMemberDuration(from: creationDate))")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Sign-in method
                            HStack(spacing: 4) {
                                Image(systemName: getSignInMethodIcon(for: user))
                                    .foregroundColor(.secondary)
                                Text(getSignInMethodText(for: user))
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .cardBackground()
                }
                
             
                    VStack(alignment: .leading, spacing: 8) {
                        Text(subscriptionModel.subscriptionStatus.description)
                            .font(.subheadline)
                            .foregroundColor(.color4)
                        
                        if case let .monthly(expiryDate) = subscriptionModel.subscriptionStatus,
                           let date = expiryDate {
                            Text("Next billing date: \(date, style: .date)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        } else if case let .annual(expiryDate) = subscriptionModel.subscriptionStatus,
                                  let date = expiryDate {
                            Text("Next billing date: \(date, style: .date)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .cardBackground()
                
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 20),
                    GridItem(.flexible(), spacing: 20)
                ], spacing: 5) {
                    
                    
                    
                    
                    
                    Button {
                        if let user = authModel.user,
                           user.providerData.contains(where: { $0.providerID == "password" }) {
                            showEmailPasswordSettings = true
                        } else {
                            // Show info alert about Apple ID management
                            alertTitle = "Apple ID Sign In"
                            alertMessage = "Your account uses Sign in with Apple. To manage your password, please visit Apple ID settings or appleid.apple.com"
                            showAlert = true
                        }
                    } label: {
                        InfoCardView(
                            icon: "lock",
                            iconColor: .color2,
                            title: authModel.user?.providerData.contains(where: { $0.providerID == "password" }) == true ? "Email & Password" : "Password Info",
                            marquee: false)
                    }
                 
                    
                    Spacer()
                    Spacer()
                        .frame(height: 20)
                           .gridCellColumns(2)
                    Spacer()
             
                    
           
                    
                    Button {
                        showSignOutAlert = true
                        
                        
                        
                    } label: {
                        InfoCardView(
                            icon: "rectangle.portrait.and.arrow.right",
                            iconColor: .color2,
                            title: "Sign Out",
                            marquee: false)
                    }
                 
                    
                    
                    Button {
                        showDeleteAccountAlert = true
                        
                   
                        
                    } label: {
                        InfoCardView(
                            icon:  "person.slash",
                            iconColor: .color8,
                            title: "Delete Account",
                            marquee: false)
                            .foregroundStyle(.color8)
                    }
                 
                    
                    
                    
                    
                }
                
                Spacer()
//                GlobalButton(title: "Sign Out") {
//                    showSignOutAlert = true
//                }
//                
//                GlobalButton(title: "Delete Account", backgroundColor: .color8) {
//                    showDeleteAccountAlert = true
//                }
//                
                
             
            }
            .padding()
        }
        .padding(.bottom, 30)
        
        .ignoresSafeArea()
        .navigationBarHidden(true)
        
        
        
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authModel.signOut()
            }
        }
        .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                showDeleteConfirmation = true
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        .alert("Confirm Deletion", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Yes, Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text(deleteAccountMessage)
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
        .sheet(isPresented: $showEmailPasswordSettings) {
            EmailPasswordSettingsView()
        }

    }
    
    
    
    private func deleteAccount() {
        isLoading = true
        
        Task {
            let (success, message) = await authModel.deleteAccount()
            
            await MainActor.run {
                isLoading = false
                alertTitle = success ? "Success" : "Error"
                alertMessage = message
                showAlert = true
            }
        }
    }
}

#Preview {
    AccountView()
}
