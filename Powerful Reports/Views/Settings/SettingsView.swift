//
//  SettingsView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 22/11/2024.
//

import SwiftUI
import _StoreKit_SwiftUI


struct SettingsView: View {
    @ObservedObject var viewModel: InspectionReportsViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authModel: AuthenticationModel


    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        
        NavigationStack{
        VStack(spacing: 0) {
            // Custom Header
            CustomHeaderVIew(title: "Settings")
            
            ScrollView {
                
              
                
                
            
                
                VStack(spacing: 24) {
                    // Account Management Section
                    
                
                    
                    
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Account")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 1) {
                            NavigationLink {
                                Text("Profile Settings")  // Placeholder view
                            } label: {
                                HStack {
                                    Text("Profile Settings")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.color0.opacity(0.3))
                                
                                
                            }
                            
                            Button {
                                viewModel.showPaywall = true
                            } label: {
                                HStack {
                                    Text("Subscription")
                                    Spacer()
                                    if viewModel.isPremium {
                                        Text("Premium")
                                            .foregroundColor(.color1)
                                    } else {
                                        Text("Free")
                                            .foregroundColor(.secondary)
                                    }
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.color0.opacity(0.3))
                            }
                            
                      
                        }
                        .cornerRadius(10)
                    }
                    
                    // Policies Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Policies")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 1) {
                            NavigationLink {
                                PolicyView(policy: .privacy)
                                
                            } label: {
                                HStack {
                                    Text("Privacy Policy")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.color0.opacity(0.3))
                            }
                            
                            NavigationLink {
                                PolicyView(policy: .terms)
                            } label: {
                                HStack {
                                    Text("Terms of Service")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.color0.opacity(0.3))
                            }
                        }
                        .cornerRadius(10)
                    }
                    
                    // Support Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Support")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 1) {
                        
                            
                            
                        
                            
                            Link(destination: URL(string: "mailto:support@powerfulreports.com")!) {
                                HStack {
                                    Text("Contact Support")
                                    Spacer()
                                    Image(systemName: "envelope")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.color0.opacity(0.3))
                            }
                        }
                        .cornerRadius(10)
                    }
                    
                    // App Info Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("App Info")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        VStack(spacing: 1) {
                            // Last Update Time
                            if let lastUpdate = viewModel.lastFirebaseUpdate {
                                HStack {
                                    Text("Last Received Data")
                                    Spacer()
                                    Text(dateFormatter.string(from: lastUpdate))
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.color0.opacity(0.3))
                            }
                            
                            
                            Spacer()
                            
                            
                            
                            
                        }
                        .cornerRadius(10)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                    
                    Button(action: {
                        authModel.signOut()
                    }) {
                        HStack {
                            
                            Text("Sign Out")
                                .foregroundColor(.red)
                            Spacer()
                        }
                        .padding()
                        .background(Color.color0.opacity(0.3))
                    }
                }
                .padding()
            

                
                .cornerRadius(10)
            }
            
                Text("Version - \(Bundle.main.appVersionLong) (\(Bundle.main.buildNumber))")
                
                
            }
        }
        .padding(.horizontal)
            
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .sheet(isPresented: $viewModel.showPaywall) {
            
            
            SubscriptionStoreView(groupID: "21595486") {
                VStack {
                    Text("Powerful Reports")
                        .font(.largeTitle)
                        .fontWeight(.black)
                    
                    Text("Access comprehensive reporting and analysis with our premium subscription!")
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.white)
                .containerBackground(.blue.gradient, for: .subscriptionStore)
            }
            .storeButton(.visible, for: .restorePurchases)
            .subscriptionStoreControlStyle(.prominentPicker)
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


