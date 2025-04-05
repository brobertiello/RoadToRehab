import Foundation
import Security

class KeychainHelper {
    
    static let standard = KeychainHelper()
    private init() {}
    
    func save(_ data: Data, service: String, account: String) {
        // Create query
        let query = [
            kSecValueData: data,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword
        ] as CFDictionary
        
        // Add data in keychain
        let status = SecItemAdd(query, nil)
        
        if status == errSecDuplicateItem {
            // Item already exists, update it
            let query = [
                kSecAttrService: service,
                kSecAttrAccount: account,
                kSecClass: kSecClassGenericPassword
            ] as CFDictionary
            
            let attributesToUpdate = [kSecValueData: data] as CFDictionary
            SecItemUpdate(query, attributesToUpdate)
        }
    }
    
    func read(service: String, account: String) -> Data? {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true
        ] as CFDictionary
        
        var result: AnyObject?
        SecItemCopyMatching(query, &result)
        
        return result as? Data
    }
    
    func delete(service: String, account: String) {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword
        ] as CFDictionary
        
        SecItemDelete(query)
    }
    
    // Convenience methods for specific auth data
    
    func saveToken(_ token: String, account: String) {
        if let data = token.data(using: .utf8) {
            save(data, service: "PTTrackerAuthToken", account: account)
        }
    }
    
    func getToken(account: String) -> String? {
        guard let data = read(service: "PTTrackerAuthToken", account: account),
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        return token
    }
    
    func saveUser(_ userData: Data, account: String) {
        save(userData, service: "PTTrackerUserData", account: account)
    }
    
    func getUserData(account: String) -> Data? {
        return read(service: "PTTrackerUserData", account: account)
    }
    
    func clearAuthData(account: String) {
        delete(service: "PTTrackerAuthToken", account: account)
        delete(service: "PTTrackerUserData", account: account)
    }
} 