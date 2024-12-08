//
//  PassIdentifiers.swift
//  meet-subscriptionstoreview-in-iOS17
//
//  Created by Huang Runhua on 6/14/23.
//

import SwiftUI

struct SubscriptionIdentifiers {
    var group: String
    var monthly: String
    var annual: String
}

extension EnvironmentValues {
    private enum SubscriptionIDsKey: EnvironmentKey {
        static var defaultValue = SubscriptionIdentifiers(
            group: "21595486",
            monthly: "Monthly",
            annual: "Annual"
        )
    }
    
    var subscriptionIDs: SubscriptionIdentifiers {
        get { self[SubscriptionIDsKey.self] }
        set { self[SubscriptionIDsKey.self] = newValue }
    }
}
