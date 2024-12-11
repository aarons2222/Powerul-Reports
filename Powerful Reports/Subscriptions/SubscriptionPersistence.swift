import Foundation

extension Notification.Name {
    static let subscriptionStatusDidChange = Notification.Name("subscriptionStatusDidChange")
}

class SubscriptionPersistence {
    static let shared = SubscriptionPersistence()
    private let defaults = UserDefaults.standard
    
    private let subscriptionStatusKey = "com.powerfulreports.subscriptionStatus"
    private let subscriptionExpiryKey = "com.powerfulreports.subscriptionExpiry"
    
    // Cache the current status to avoid frequent UserDefaults reads
    private var cachedStatus: SubscriptionStatus?
    private var lastExpiryCheck: Date?
    private let expiryCheckInterval: TimeInterval = 60 // Check expiry once per minute
    
    private init() {}
    
    func saveSubscriptionStatus(_ status: SubscriptionStatus) {
        // If the status hasn't changed, don't write to UserDefaults
        if case .notSubscribed = status, case .notSubscribed = cachedStatus {
            return
        }
        
        if let cached = cachedStatus {
            switch (status, cached) {
            case (.monthly(let newExpiry), .monthly(let oldExpiry)) where newExpiry == oldExpiry:
                return
            case (.annual(let newExpiry), .annual(let oldExpiry)) where newExpiry == oldExpiry:
                return
            default:
                break
            }
        }
        
        var statusString: String
        var expiryDate: Date?
        
        switch status {
        case .notSubscribed:
            statusString = "notSubscribed"
        case .monthly(let expiry):
            statusString = "monthly"
            expiryDate = expiry
        case .annual(let expiry):
            statusString = "annual"
            expiryDate = expiry
        }
        
        print("SubscriptionPersistence: Saving status: \(statusString), expiry: \(String(describing: expiryDate))")
        
        // Update cache first
        cachedStatus = status
        lastExpiryCheck = Date()
        
        // Batch write to UserDefaults
        defaults.setValue(statusString, forKey: subscriptionStatusKey)
        if let expiryDate {
            defaults.setValue(expiryDate, forKey: subscriptionExpiryKey)
        } else {
            defaults.removeObject(forKey: subscriptionExpiryKey)
        }
        
        let previousIsPremium = isPremium
        if previousIsPremium != isPremium {
            NotificationCenter.default.post(name: .subscriptionStatusDidChange, object: nil)
        }
    }
    
    func loadSubscriptionStatus() -> SubscriptionStatus {
        // Check if we have a cached status and if it's still valid
        if let lastCheck = lastExpiryCheck,
           Date().timeIntervalSince(lastCheck) < expiryCheckInterval,
           let cachedStatus = cachedStatus {
            return cachedStatus
        }
        
        let statusString = defaults.string(forKey: subscriptionStatusKey) ?? "notSubscribed"
        let expiryDate = defaults.object(forKey: subscriptionExpiryKey) as? Date
        
        // Check if the subscription has expired
        if let expiryDate = expiryDate {
            print("SubscriptionPersistence: Checking saved expiry date: \(expiryDate)")
            if expiryDate <= Date() {
                print("SubscriptionPersistence: Saved subscription has expired")
                let status = SubscriptionStatus.notSubscribed
                cachedStatus = status
                lastExpiryCheck = Date()
                return status
            }
        }
        
        let status: SubscriptionStatus
        switch statusString {
        case "monthly":
            status = .monthly(expiryDate: expiryDate)
        case "annual":
            status = .annual(expiryDate: expiryDate)
        default:
            status = SubscriptionStatus.notSubscribed
        }
        
        // Update cache
        cachedStatus = status
        lastExpiryCheck = Date()
        return status
    }
    
    var isPremium: Bool {
        // Use cached value if available and recently checked
        if let lastCheck = lastExpiryCheck,
           Date().timeIntervalSince(lastCheck) < expiryCheckInterval,
           let cachedStatus = cachedStatus {
            switch cachedStatus {
            case .notSubscribed:
                return false
            case .monthly(let expiryDate), .annual(let expiryDate):
                return expiryDate.map { $0 > Date() } ?? false
            }
        }
        
        let status = loadSubscriptionStatus()
        switch status {
        case .notSubscribed:
            return false
        case .monthly(let expiryDate), .annual(let expiryDate):
            guard let expiryDate else { return false }
            let isValid = expiryDate > Date()
            print("SubscriptionPersistence: Checking premium status - Expiry: \(expiryDate), Is Valid: \(isValid)")
            return isValid
        }
    }
}
