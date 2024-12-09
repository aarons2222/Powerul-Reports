//
//  SettingsView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 22/11/2024.
//

import SwiftUI
import _StoreKit_SwiftUI


struct SettingsView: View {
    
    @EnvironmentObject var authModel: AuthenticationViewModel
    @ObservedObject var viewModel: InspectionReportsViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(SubscriptionStatusModel.self) private var subscriptionStatusModel
    @Environment(\.subscriptionIDs) private var subscriptionIDs
    
    @State private var showSignOutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showDeleteConfirmation = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var presentingSubscriptionSheet = false
    
    
    
    @State private var showPaywall: Bool = false
    @State private var status: EntitlementTaskState<SubscriptionStatus> = .loading
 
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    
    
    var deleteAccountMessage: String {
        if let user = authModel.user,
           user.providerData.first(where: { $0.providerID == "apple.com" }) != nil {
            return "This will permanently delete your account and revoke the associated Apple ID credentials. This action CANNOT be undone. Are you absolutely sure?"
        }
        return "This will permanently delete your account and all associated data. This action CANNOT be undone. Are you absolutely sure?"
    }
    
    private var subscriptionInfo: (title: String, detail: String, color: Color) {
        switch subscriptionStatusModel.subscriptionStatus {
        case .notSubscribed:
            return ("Demo Mode", "Upgrade to access your reports", .secondary)
        case .monthly(let expiryDate):
            if let date = expiryDate {
                return ("Premium Monthly", "Expires: \(formatDate(date))", .color2)
            }
            return ("Premium Monthly", "Active", .color2)
        case .annual(let expiryDate):
            if let date = expiryDate {
                return ("Premium Annual", "Expires: \(formatDate(date))", .color2)
            }
            return ("Premium Annual", "Active", .color2)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CustomHeaderVIew(title: "Settings")
                
                ScrollView {
                    VStack(spacing: 20) {
                        // User Profile Section
                        if let user = authModel.user {
                            CustomCardView("Profile") {
                                VStack(spacing: 16) {
                                    // Email Initial Avatar
                                    Circle()
                                        .fill(Color.color2.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            Text((user.email?.prefix(1).uppercased() ?? "?"))
                                                .font(.title2.bold())
                                                .foregroundColor(.color2)
                                        )
                                    
                                    // User Info
                                    VStack(spacing: 8) {
                                        Text(user.email ?? "No email")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Text(user.providerData.first?.providerID == "apple.com" ? "Sign in with Apple" : "Email and Password")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        if let creationDate = user.metadata.creationDate {
                                            Text("Member since \(dateFormatter.string(from: creationDate))")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                            }
                        }
                        
                        
                        CustomCardView("Subscription") {
                            planView

                            if subscriptionStatusModel.subscriptionStatus == .notSubscribed {
                                Button {
                                    self.showPaywall = true
                                } label: {
                                    HStack{
                                        Spacer()
                                        Text("View Subscriptions")
                                    }
                                }
                            }
                        }
                        
                  
                        
                        // Last Update Section
                        CustomCardView("Last Update") {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.color2)
                                Text("Last Received Data:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                if let lastUpdate = viewModel.lastFirebaseUpdate {
                                    Text(dateFormatter.string(from: lastUpdate))
                                        .foregroundColor(.primary)
                                } else {
                                    Text("Never")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                        }
                        
                        // Policies Section
                        CustomCardView("Policies") {
                            VStack(spacing: 1) {
                                NavigationLink {
                                    PolicyView(policy: .privacy)
                                } label: {
                                    HStack {
                                        Image(systemName: "lock.shield")
                                            .foregroundColor(.color2)
                                        Text("Privacy Policy")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray.opacity(0.5))
                                    }
                                    .padding()
                                }
                                
                                Divider()
                                
                                NavigationLink {
                                    PolicyView(policy: .terms)
                                } label: {
                                    HStack {
                                        Image(systemName: "doc.text")
                                            .foregroundColor(.color2)
                                        Text("Terms of Service")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray.opacity(0.5))
                                    }
                                    .padding()
                                }
                            }
                        }
                        
                        // Support Section
                        CustomCardView("Support") {
                            Link(destination: URL(string: "mailto:support@powerfulreports.com")!) {
                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundColor(.color2)
                                    Text("Contact Support")
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .foregroundColor(.gray.opacity(0.5))
                                }
                                .padding()
                            }
                        }
                        
                        // App Info Section
                        CustomCardView("App Info") {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Version")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(Bundle.main.appVersionLong)
                                        .foregroundColor(.primary)
                                }
                                
                                HStack {
                                    Text("Build")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(Bundle.main.buildNumber)
                                        .foregroundColor(.primary)
                                }
                            }
                            .padding()
                        }
                        
                        // Account Management Section
                        CustomCardView("Account Management") {
                            VStack(spacing: 1) {
                                Button(action: { showSignOutAlert = true }) {
                                    HStack {
                                        Image(systemName: "rectangle.portrait.and.arrow.right")
                                            .foregroundColor(.red)
                                        Text("Sign Out")
                                            .foregroundColor(.red)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray.opacity(0.5))
                                    }
                                    .padding()
                                }
                                
                                Divider()
                                
                                Button(action: { showDeleteAccountAlert = true }) {
                                    HStack {
                                        Image(systemName: "person.crop.circle.badge.minus")
                                            .foregroundColor(.red)
                                        Text("Delete Account")
                                            .foregroundColor(.red)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.gray.opacity(0.5))
                                    }
                                    .padding()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                }
            }
            .background(Color.gray.opacity(0.1))
            .ignoresSafeArea()
            .navigationBarHidden(true)
        }
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

            .sheet(isPresented: $showPaywall, content: {
                Paywall()
            })
     

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

// Bundle extension for version info
extension Bundle {
    var appVersionLong: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView(viewModel: InspectionReportsViewModel())
        }
    }
}



extension SettingsView {
    @ViewBuilder
    var planView: some View {
        VStack(alignment: .leading, spacing: 3) {
 
            
       
            if case let .monthly(expiryDate) = subscriptionStatusModel.subscriptionStatus,
               let date = expiryDate {
                Text("Powerful Reports Monthly")
                    .font(.system(size: 17))
                
                Text("Expires: \(formatDate(date))")
                    .font(.system(size: 15))
                    .foregroundStyle(.blue)
            } else if case let .annual(expiryDate) = subscriptionStatusModel.subscriptionStatus,
                      let date = expiryDate {
                
                Text("Powerful Reports Annual")
                    .font(.system(size: 17))
                Text("Expires: \(formatDate(date))")
                    .font(.system(size: 15))
                    .foregroundStyle(.blue)
            }else{
                Text("Not Subscribed")
                    .font(.system(size: 17))
            }
            

            
            
            if subscriptionStatusModel.subscriptionStatus != .notSubscribed {
                Button("Handle Subscription \(Image(systemName: "chevron.forward"))") {
                    self.presentingSubscriptionSheet = true
                }
            }
        }
    }
    
  
}
