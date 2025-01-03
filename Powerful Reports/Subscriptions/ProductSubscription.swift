//
//  ProductSubscription.swift
//  meet-subscriptionstoreview-in-iOS17
//
//  Created by Huang Runhua on 6/15/23.
//
import Foundation
import StoreKit

actor ProductSubscription {
    static let shared = ProductSubscription()
    
    private init() {
        print("ProductSubscription: Instance initialized")
        Task {
            await publicRefreshSubscriptionStatus()
        }
    }
    
    public func publicRefreshSubscriptionStatus() async {
        print("ProductSubscription: Refreshing subscription status")
  
            for await result in Transaction.currentEntitlements {
                await process(transaction: result)
            }
    }
    
    // Subscription Only Handle Here.
    func status(for statuses: [Product.SubscriptionInfo.Status], ids: SubscriptionIdentifiers) async -> SubscriptionStatus {
        print("ProductSubscription: Checking status for \(statuses.count) status(es)")
        
        let effectiveStatus = statuses.max { lhs, rhs in
            let lhsStatus = SubscriptionStatus(
                productID: lhs.transaction.unsafePayloadValue.productID,
                ids: ids
            ) ?? SubscriptionStatus.notSubscribed
            let rhsStatus = SubscriptionStatus(
                productID: rhs.transaction.unsafePayloadValue.productID,
                ids: ids
            ) ?? SubscriptionStatus.notSubscribed
            return lhsStatus < rhsStatus
        }
        
        guard let effectiveStatus else {
            print("ProductSubscription: No effective status found")
            let status = SubscriptionStatus.notSubscribed
            await MainActor.run {
                 SubscriptionPersistence.shared.saveSubscriptionStatus(status)
            }
            return status
        }
        
        let transaction: Transaction
        switch effectiveStatus.transaction {
        case .verified(let t):
            print("ProductSubscription: Transaction verified for product: \(t.productID)")
            transaction = t
        case .unverified(let t, let error):
            print("ProductSubscription: Transaction verification failed: \(error)")
            // Retry verification once before giving up
            if let verifiedTransaction = await retryVerification(transaction: t) {
                transaction = verifiedTransaction
            } else {
                let status = SubscriptionStatus.notSubscribed
                await MainActor.run {
                     SubscriptionPersistence.shared.saveSubscriptionStatus(status)
                }
                return status
            }
        }
        
        // Check if the subscription has expired
        if let expirationDate = transaction.expirationDate {
            print("ProductSubscription: Checking expiration date: \(expirationDate)")
            if expirationDate <= Date() {
                print("ProductSubscription: Subscription has expired")
                let status = SubscriptionStatus.notSubscribed
                await MainActor.run {
                     SubscriptionPersistence.shared.saveSubscriptionStatus(status)
                }
                return status
            }
        }
        
        guard let subscriptionStatus = SubscriptionStatus(
            productID: transaction.productID,
            ids: ids,
            expiryDate: transaction.expirationDate
        ) else {
            print("ProductSubscription: Could not create subscription status")
            let status = SubscriptionStatus.notSubscribed
            await MainActor.run {
                 SubscriptionPersistence.shared.saveSubscriptionStatus(status)
            }
            return status
        }
        
        print("ProductSubscription: Returning subscription status: \(subscriptionStatus)")
        await MainActor.run {
             SubscriptionPersistence.shared.saveSubscriptionStatus(subscriptionStatus)
        }
        return subscriptionStatus
    }
    
    private func retryVerification(transaction: Transaction) async -> Transaction? {
        print("ProductSubscription: Retrying verification for transaction \(transaction.id)")
        do {
            // Add a small delay before retrying
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            let result = await Transaction.latest(for: String(transaction.id))
            switch result {
            case .verified(let transaction):
                return transaction
            case .unverified(_, let error):
                print("ProductSubscription: Retry verification failed: \(error)")
                return nil
          
             default:
                print("ProductSubscription: Unknown verification result")
                return nil
            }
        } catch {
            print("ProductSubscription: Error during retry verification: \(error)")
            return nil
        }
    }
}

extension ProductSubscription {
    func process(transaction verificationResult: VerificationResult<Transaction>) async {
        let unsafeTransaction = verificationResult.unsafePayloadValue
        print("ProductSubscription: Processing transaction \(unsafeTransaction.id) for \(unsafeTransaction.productID)")
        
        let transaction: Transaction
        switch verificationResult {
        case .verified(let t):
            print("ProductSubscription: Transaction \(t.id) verified successfully")
            transaction = t
        case .unverified(let t, let error):
            print("ProductSubscription: Transaction \(t.id) verification failed: \(error)")
            return
        }
        
        await transaction.finish()
        print("ProductSubscription: Transaction \(transaction.id) finished")
    }
    
    func checkForUnfinishedTransactions() async {
        print("ProductSubscription: Checking for unfinished transactions")
        for await transaction in Transaction.unfinished {
            Task.detached(priority: .background) {
                print("ProductSubscription: Processing unfinished transaction \(transaction.unsafePayloadValue.id)")
                await self.process(transaction: transaction)
            }
        }
    }
    
    func observeTransactionUpdates() async {
        print("ProductSubscription: Starting transaction updates observation")
        for await update in Transaction.updates {
            await self.process(transaction: update)
        }
    }
}
