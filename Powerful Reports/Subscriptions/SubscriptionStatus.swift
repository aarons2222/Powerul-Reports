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
            if let expiryDate {
                "Monthly (Expires \(Self.formatDate(expiryDate)))"
            } else {
                "Monthly"
            }
        case .annual(let expiryDate):
            if let expiryDate {
                "Annual (Expires \(Self.formatDate(expiryDate)))"
            } else {
                "Annual"
            }
        }
    }
    
    var rawValue: String {
        switch self {
        case .notSubscribed:
            return "notSubscribed"
        case .monthly(let expiryDate):
            if let expiryDate {
                return "monthly_\(expiryDate.timeIntervalSince1970)"
            }
            return "monthly"
        case .annual(let expiryDate):
            if let expiryDate {
                return "annual_\(expiryDate.timeIntervalSince1970)"
            }
            return "annual"
        }
    }
    
    init?(rawValue: String) {
        if rawValue == "notSubscribed" {
            self = .notSubscribed
            return
        }
        
        let components = rawValue.split(separator: "_")
        if components.count == 2, let timestamp = Double(components[1]) {
            let expiryDate = Date(timeIntervalSince1970: timestamp)
            switch components[0] {
            case "monthly":
                self = .monthly(expiryDate: expiryDate)
            case "annual":
                self = .annual(expiryDate: expiryDate)
            default:
                return nil
            }
        } else {
            switch rawValue {
            case "monthly":
                self = .monthly(expiryDate: nil)
            case "annual":
                self = .annual(expiryDate: nil)
            default:
                return nil
            }
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
