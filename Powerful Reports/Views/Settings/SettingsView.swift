//
//  SettingsView.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 22/11/2024.
//

import SwiftUI
import _StoreKit_SwiftUI
import MessageUI

struct SettingsView: View {
    
    @EnvironmentObject var authModel: AuthenticationViewModel
    @ObservedObject var viewModel: InspectionReportsViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(SubscriptionStatusModel.self) private var subscriptionStatusModel
    @Environment(\.subscriptionIDs) private var subscriptionIDs
    

    @State private var presentingSubscriptionSheet = false
    @State private var showShareSheet = false
    
    
    
    @State private var showPaywall: Bool = false
    @State private var status: EntitlementTaskState<SubscriptionStatus> = .loading
 
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CustomHeaderVIew(title: "Settings")
                
                
                ScrollView {
                    
                    Color.clear.frame(height: 20)
                    
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
                            }
                            
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .cardBackground()
                    }
                    
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 20),
                        GridItem(.flexible(), spacing: 20)
                    ], spacing: 5) {
                     
                        
                        
                        SectionHeaderView(title: "Account")
                            .font(.headline)
                            .foregroundColor(.color2)
                            .padding(.horizontal)
                            .padding(.top)
                            .gridCellColumns(2)
                        Spacer()
                        
                        
                        
                        if subscriptionStatusModel.subscriptionStatus == .notSubscribed {
                            Button {
                                self.showPaywall = true
                            } label: {
                                InfoCardView(
                                    icon: "storefront",
                                    iconColor: .color2,
                                    title: "Not Subscribed",
                                    subtitle: "View Plans")
                            }
                        } else {
                            let expiryDate: String = {
                                switch subscriptionStatusModel.subscriptionStatus {
                                case .monthly(let date), .annual(let date):
                                    if let date {
                                        return "Expires: " + dateFormatter.string(from: date)
                                    }
                                    return "Active"
                                case .notSubscribed:
                                    return "Not Active"
                                }
                            }()
                            
                            Button {
                                self.presentingSubscriptionSheet = true
                            } label: {
                                InfoCardView(
                                    icon: "storefront",
                                    iconColor: .color2,
                                    title: "Active Plan",
                                    subtitle: expiryDate)
                            }
                        }
                        
                       
                        
                        
                    

                        
                        NavigationLink(destination: AccountView()){
                            
                            InfoCardView(
                                icon: "person",
                                iconColor: .color2,
                                title: "Manage Account",
                                subtitle: "Your Controls")
                               
                        }
                
                        
                        
                        
                        SectionHeaderView(title: "Get Involved")
                            .gridCellColumns(2)
                        Spacer()
                        
                        
                        Link(destination: URL(string: "https://www.powerfulpractitioners.co.uk")!) {
                            InfoCardView(
                                icon: "globe",
                                iconColor: .color2,
                                title: "Visit Our Website",
                                subtitle: "Discover More")
                        }
                        
                        
           
                   
                        Button {
                            self.showShareSheet = true
                            
                            
                            
                        } label: {
                            InfoCardView(
                                icon: "person.3.sequence",
                                iconColor: .color2,
                                title: "Share Our App",
                                subtitle: "Empower Others")
                        }
                     
                        
                     
                        
                        
                        
                        
                        // Policies Section
                        SectionHeaderView(title: "Policies")
                            .gridCellColumns(2)
                        Spacer()
                        
                        NavigationLink {
                            PolicyView(policy: .privacy)
                        } label: {
                            InfoCardView(
                                icon: "lock.shield",
                                iconColor: .color2,
                                title: "Privacy Policy",
                                subtitle: "Our Promise")
                        }
                        
                        NavigationLink {
                            PolicyView(policy: .terms)
                        } label: {
                            InfoCardView(
                                icon: "doc.text",
                                iconColor: .color2,
                                title: "Terms of Service",
                                subtitle: "The Rules")
                        }
                        
                        // Support Section
                        SectionHeaderView(title: "Support")
                            .gridCellColumns(2)
                        Spacer()
                        
                        Link(destination: URL(string: "mailto:support@powerfulreports.com")!) {
                            InfoCardView(
                                icon: "envelope",
                                iconColor: .color2,
                                title: "Contact Support",
                                subtitle: "We're Here")
                        }
                        .gridCellColumns(2)
                  
                        
                   
                    
              
                    
                    }
                    .padding(.vertical, 20)
                    
                    
                    Text("Version \(Bundle.main.appVersionLong)")
                        .foregroundColor(.gray)
                        .padding()
                    
                    
                 
             
                }
                .scrollIndicators(.hidden)
                .padding(.horizontal)
            }
            .background(Color.gray.opacity(0.1))
            .ignoresSafeArea()
            .navigationBarHidden(true)
        }
    
            .sheet(isPresented: $showPaywall, content: {
                Paywall()
            })
     
            .manageSubscriptionsSheet(
                isPresented: $presentingSubscriptionSheet,
                subscriptionGroupID: subscriptionIDs.group
            )
        
            .sheet(isPresented: $showShareSheet, content: {
                ShareSheetView()
            })

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

struct SectionHeaderView: View {
    let title: String
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.top)
    }
}

struct InfoCardView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    
  
    
    init(
        icon: String = "info.circle",
        iconColor: Color = .color2,
        title: String = "title",
        subtitle: String? = nil
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Spacer()
            
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(iconColor)
                .padding(.top, 12)
            
            VStack(spacing: 4) {
                Text(title)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                
                if let subtitle {
                    Text(subtitle)
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }
            }
            .padding(.bottom, 12)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .frame(height: 130)
        .cardBackground()
    }
}
