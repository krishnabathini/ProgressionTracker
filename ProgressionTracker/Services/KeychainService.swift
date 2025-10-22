//
//  KeychainService.swift
//  ProgressionTracker
//
//  Created on 10/21/2025
//

import Foundation
import Security

/// Service for securely storing and retrieving sensitive data in the iOS Keychain
class KeychainService {
    // MARK: - Singleton
    static let shared = KeychainService()
    
    // MARK: - Constants
    private let service = "com.progressiontracker.gitlifting"
    private let accessTokenKey = "github_access_token"
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    
    /// Saves the GitHub access token securely to the Keychain
    /// - Parameter token: The access token to save
    /// - Returns: True if the save was successful, false otherwise
    @discardableResult
    func saveAccessToken(_ token: String) -> Bool {
        // First, delete any existing token
        deleteAccessToken()
        
        guard let tokenData = token.data(using: .utf8) else {
            print("Failed to convert token to data")
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accessTokenKey,
            kSecValueData as String: tokenData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("Successfully saved access token to Keychain")
            return true
        } else {
            print("Failed to save access token to Keychain: \(status)")
            return false
        }
    }
    
    /// Retrieves the GitHub access token from the Keychain
    /// - Returns: The access token if found, nil otherwise
    func getAccessToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accessTokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let token = String(data: data, encoding: .utf8) {
            return token
        } else if status == errSecItemNotFound {
            print("No access token found in Keychain")
            return nil
        } else {
            print("Failed to retrieve access token from Keychain: \(status)")
            return nil
        }
    }
    
    /// Deletes the GitHub access token from the Keychain
    /// - Returns: True if the deletion was successful, false otherwise
    @discardableResult
    func deleteAccessToken() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accessTokenKey
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            print("Successfully deleted access token from Keychain")
            return true
        } else {
            print("Failed to delete access token from Keychain: \(status)")
            return false
        }
    }
    
    /// Checks if an access token exists in the Keychain
    /// - Returns: True if a token exists, false otherwise
    func hasAccessToken() -> Bool {
        return getAccessToken() != nil
    }
    
    /// Updates an existing access token
    /// - Parameter token: The new access token
    /// - Returns: True if the update was successful, false otherwise
    @discardableResult
    func updateAccessToken(_ token: String) -> Bool {
        guard let tokenData = token.data(using: .utf8) else {
            print("Failed to convert token to data")
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: accessTokenKey
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: tokenData
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        if status == errSecSuccess {
            print("Successfully updated access token in Keychain")
            return true
        } else if status == errSecItemNotFound {
            // If item doesn't exist, create it
            return saveAccessToken(token)
        } else {
            print("Failed to update access token in Keychain: \(status)")
            return false
        }
    }
}

// MARK: - Additional Keychain Utilities

extension KeychainService {
    /// Clears all data stored by this app in the Keychain
    func clearAllData() {
        deleteAccessToken()
    }
    
    /// Returns debug information about the Keychain status
    func debugInfo() -> String {
        var info = "Keychain Debug Info:\n"
        info += "Service: \(service)\n"
        info += "Has Access Token: \(hasAccessToken())\n"
        
        if let token = getAccessToken() {
            let masked = String(repeating: "*", count: max(0, token.count - 4)) + token.suffix(4)
            info += "Token (masked): \(masked)\n"
        }
        
        return info
    }
}

