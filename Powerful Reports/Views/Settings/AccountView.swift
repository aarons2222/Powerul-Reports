//
//  AccountView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 10/12/2024.
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject var authModel: AuthenticationViewModel
    @State private var showSignOutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showDeleteConfirmation = false
    
    
    
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
  
    
    var deleteAccountMessage: String {
        if let user = authModel.user,
           user.providerData.first(where: { $0.providerID == "apple.com" }) != nil {
            return "This will permanently delete your account and revoke the associated Apple ID credentials. This action CANNOT be undone. Are you absolutely sure?"
        }
        return "This will permanently delete your account and all associated data. This action CANNOT be undone. Are you absolutely sure?"
    }
    
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            CustomHeaderVIew(title: "Account")
            Spacer()
            
            
            
            
            
            
            // Bottom Actions
            VStack(spacing: 16) {
                GlobalButton(title: "Sign Out") {
                    showSignOutAlert = true
                }
                
                GlobalButton(title: "Delete Account", backgroundColor: .color8) {
                    showDeleteAccountAlert = true
                }
                
                
             
            }
            .padding(.horizontal)
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
