//
//  SubscriptionShopView.swift
//  meet-subscriptionstoreview-in-iOS17
//
//  Created by Huang Runhua on 6/14/23.
//

import SwiftUI
import StoreKit

struct Paywall: View {
    @Environment(\.subscriptionIDs.group) private var subscriptionGroupID
    
    var body: some View {
        SubscriptionStoreView(groupID: subscriptionGroupID) {
            PaywallContent()
        }
        .backgroundStyle(.clear)
        .subscriptionStoreButtonLabel(.multiline)
        .subscriptionStorePickerItemBackground(.thinMaterial)
        .storeButton(.visible, for: .restorePurchases)
    }
}

#Preview {
    Paywall()
}
