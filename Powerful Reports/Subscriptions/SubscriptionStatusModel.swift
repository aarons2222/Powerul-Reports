//
//  SubscriptionStatusModel.swift
//  Powerful Reports/Subscriptions
//
//  Created by Huang Runhua on 6/14/23.
//

import Foundation
import Observation

@Observable class SubscriptionStatusModel {
    var subscriptionStatus: SubscriptionStatus {
        didSet {
            // Save the status whenever it changes
            SubscriptionPersistence.shared.saveSubscriptionStatus(subscriptionStatus)
        }
    }
    
    init() {
        // Initialize with a default value first
        self.subscriptionStatus = .notSubscribed
        // Then load from persistence if available
        self.subscriptionStatus = SubscriptionPersistence.shared.loadSubscriptionStatus()
    }
}
