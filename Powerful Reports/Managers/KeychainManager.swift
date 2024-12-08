import Foundation
import Security

enum KeychainError: Error {
    case duplicateEntry
    case unknown(OSStatus)
    case itemNotFound
    case invalidItemFormat
}

class KeychainManager {
    static let shared = KeychainManager()
    private let service = Bundle.main.bundleIdentifier ?? "com.powerfulreports.credentials"
    
    private init() {}
    
    func saveCredentials(email: String, password: String) throws {
        // First, try to delete any existing credentials
        try? deleteCredentials()
        
        let credentials = "\(email):\(password)".data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: email,
            kSecValueData as String: credentials,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }
    
    func retrieveCredentials() throws -> (email: String, password: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let credentials = String(data: data, encoding: .utf8),
              let separatorIndex = credentials.firstIndex(of: ":")
        else {
            throw KeychainError.itemNotFound
        }
        
        let email = String(credentials[..<separatorIndex])
        let password = String(credentials[credentials.index(after: separatorIndex)...])
        
        return (email, password)
    }
    
    func deleteCredentials() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }
}
