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
        formatter.timeStyle = .short
        return formatter
    }()
    


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
                return ("Premium Monthly", "Expires: \(date)", .color2)
            }
            return ("Premium Monthly", "Active", .color2)
        case .annual(let expiryDate):
            if let date = expiryDate {
                return ("Premium Annual", "Expires: \(date)", .color2)
            }
            return ("Premium Annual", "Active", .color2)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                CustomHeaderVIew(title: "Settings")
                
                
                ScrollView {
                    
            
                    
         
                    
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 20),
                        GridItem(.flexible(), spacing: 20)
                    ], spacing: 5) {
                     
                        
                        SectionHeaderView(title: "Account")
                            .padding(.top)
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
                                        return dateFormatter.string(from: date)
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
                                    subtitle: expiryDate,
                                    marquee: true)
                            }
                        }
                        
                       
                        
                        
                    

                        
                        NavigationLink(destination: AccountView()){
                            
                            InfoCardView(
                                icon: "person",
                                iconColor: .color2,
                                title: "Manage Account",
                                subtitle: "Your Controls",
                                marquee: false)
                               
                        }
                
                        
                        
                        
                        SectionHeaderView(title: "Get Involved")
                            .gridCellColumns(2)
                        Spacer()
                        
                        
                        Link(destination: URL(string: "https://www.powerfulpractitioners.co.uk")!) {
                            InfoCardView(
                                icon: "globe",
                                iconColor: .color2,
                                title: "Visit Our Website",
                                subtitle: "Discover More",
                                marquee: false)
                        }
                        
                        
           
                   
                        Button {
                            self.showShareSheet = true
                            
                            
                            
                        } label: {
                            InfoCardView(
                                icon: "person.3.sequence",
                                iconColor: .color2,
                                title: "Share Our App",
                                subtitle: "Empower Others",
                                marquee: false)
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
                                subtitle: "Our Promise",
                                marquee: false)
                        }
                        
                        NavigationLink {
                            PolicyView(policy: .terms)
                        } label: {
                            InfoCardView(
                                icon: "doc.text",
                                iconColor: .color2,
                                title: "Terms of Service",
                                subtitle: "The Rules",
                                marquee: false)
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
                                subtitle: "We're Here",
                                marquee: false)
                        }
                        .gridCellColumns(2)
                  
                        
                   
                    
              
                    
                    }
                    .padding(.bottom, 10)
                    
                    
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
    let marquee: Bool
    
  
    
    init(
        icon: String = "info.circle",
        iconColor: Color = .color2,
        title: String = "title",
        subtitle: String? = nil,
        marquee: Bool = false

    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.marquee = marquee

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
                                    if marquee {
                                        HStack(spacing: 0){
                                            Text("Expires:  ")
                                            
                                            Text(subtitle)
                                                .marquee()
                                        }
                                        .foregroundColor(.secondary)
                                        .font(.footnote)
                                       
                                    } else {
                                        Text(subtitle)
                                            .foregroundColor(.secondary)
                                            .font(.footnote)
                                    }
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


import SwiftUI

extension View {
    func marquee() -> some View {
        modifier(MarqueeModifier())
    }
}

struct MarqueeModifier: ViewModifier {
    @State private var animate = false
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 30) {
                    content
                    content
                }
                .fixedSize(horizontal: true, vertical: false)
                .offset(x: animate ? -geometry.size.width : 0)
                .animation(
                    .linear(duration: 10)
                    .repeatForever(autoreverses: false),
                    value: animate
                )
                .onAppear {
                    animate = true
                }
            }
        }
    }
}

