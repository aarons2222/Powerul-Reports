//
//  SubscriptionShopContent.swift
//  meet-subscriptionstoreview-in-iOS17
//
//  Created by Huang Runhua on 6/15/23.
//

import SwiftUI
import StoreKit

struct Paywall: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.subscriptionIDs.group) private var subscriptionGroupID
    @Environment(\.dismiss) private var dismiss
    @State private var showThankYouToast = false

    let privacy: URL = URL("https://www.powerfulpractitioners.co.uk/privacy-policy")
    let terms: URL = URL("https://www.powerfulpractitioners.co.uk/terms-of-use")
      
    
    var body: some View {
        
        
        
        SubscriptionStoreView(groupID: subscriptionGroupID) {
            VStack(spacing: 25) {
                headerView
                featuresView
            }
            .padding(.top, 30)
        }
        .storeButton(.visible, for: .redeemCode)
        .storeButton(.visible, for: .restorePurchases)
        .subscriptionStorePolicyDestination(url: privacy, for: .privacyPolicy)
        .subscriptionStorePolicyDestination(url: terms, for: .termsOfService)
        
        .backgroundStyle(.clear)
        .subscriptionStorePickerItemBackground(.thinMaterial)
        .subscriptionStoreControlStyle(.automatic)
        .storeButton(.visible)
        .buttonBorderShape(.capsule)
        .tint(.color1)
        .onInAppPurchaseCompletion { product, result in
            switch result {
            case .success(let purchaseResult):
                switch purchaseResult {
                case .success(let transaction):
                    showThankYouToast = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                    
                    print("Transaction \(transaction)")
                case .pending:
                    print("Purchase is pending approval")
                case .userCancelled:
                    print("Purchase was cancelled by user")
                @unknown default:
                    print("Unknown purchase result")
                }
            case .failure(let error):
                print("Purchase error: \(error.localizedDescription)")
            }
        }
        .overlay {
            if showThankYouToast {
                VStack {
                    
                    Text("Thank you for subscribing!")
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            Capsule()
                                .fill(.color1)
                        )
                        .padding(.vertical, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    
                    Spacer()
                }
                .animation(.spring(), value: showThankYouToast)
            }
        }
        .background {
            ZStack {
                LinearGradient(
                    colors: [.color2.opacity(0.1), .color3.opacity(0.1)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                Circle()
                    .fill(.color2.opacity(0.1))
                    .blur(radius: 50)
                    .offset(x: -100, y: -100)
                
                Circle()
                    .fill(.color3.opacity(0.1))
                    .blur(radius: 50)
                    .offset(x: 100, y: 100)
            }
            .ignoresSafeArea()
        }
        
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis.ascending.badge.clock")
                .font(.system(size: 60))
                .foregroundStyle(.color2, .color3)
                .symbolEffect(.pulse)
            
            Text("Unlock Ofsted Insights")
                .font(.largeTitle)
                .bold()
                .foregroundStyle(
                    LinearGradient(
                        colors: [.color2, .color3],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("Access detailed analysis of Ofsted inspection trends")
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var featuresView: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureRow(icon: "chart.xyaxis.line", title: "Trend Analysis", description: "Track inspection outcomes and ratings over 12 months")
            FeatureRow(icon: "magnifyingglass.circle", title: "Deep Insights", description: "Compare performance across regions and inspectors")
            FeatureRow(icon: "doc.text.magnifyingglass", title: "Historical Data", description: "12-month historical analysis and benchmarking")
        }
        .padding(.horizontal)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(.color2, .color3)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .contentTransition(.numericText())
    }
}


// force unwrap URL
extension URL {
    init(_ string: StaticString) {
        self.init(string: "\(string)")!
    }
}
