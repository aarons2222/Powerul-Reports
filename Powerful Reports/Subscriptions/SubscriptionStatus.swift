//
//  SubscriptionStatus.swift
//  meet-subscriptionstoreview-in-iOS17
//
//  Created by Huang Runhua on 6/14/23.
//

import Foundation
import StoreKit


enum SubscriptionStatus: Comparable, Hashable {
    case notSubscribed
    case monthly(expiryDate: Date?)
    case annual(expiryDate: Date?)
    
    init?(productID: Product.ID, ids: SubscriptionIdentifiers, expiryDate: Date? = nil) {
        switch productID {
        case ids.monthly: self = .monthly(expiryDate: expiryDate)
        case ids.annual: self = .annual(expiryDate: expiryDate)
        default: return nil
        }
    }
    
    var description: String {
        switch self {
        case .notSubscribed:
            "Not Subscribed"
        case .monthly(let expiryDate):
         
                "Monthly"
            
        case .annual(let expiryDate):
          
                "Annual"
            
        }
    }
    
    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    static func < (lhs: SubscriptionStatus, rhs: SubscriptionStatus) -> Bool {
        switch (lhs, rhs) {
        case (.notSubscribed, _):
            return true
        case (_, .notSubscribed):
            return false
        case (.monthly, .annual):
            return true
        case (.annual, .monthly):
            return false
        case (.monthly, .monthly), (.annual, .annual):
            return false
        }
    }
}
