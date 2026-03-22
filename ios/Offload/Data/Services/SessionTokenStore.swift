// Purpose: Session token storage protocol and implementations (in-memory + Keychain).
// Authority: Code-level
// Governed by: CLAUDE.md

import Foundation
import Security

// MARK: - SessionTokenStore Protocol

protocol SessionTokenStore: AnyObject {
    var token: String? { get set }
    var expiresAt: Date? { get set }
    func clear()
}

/// In-memory session token store for testing.
final class InMemorySessionTokenStore: SessionTokenStore {
    var token: String?
    var expiresAt: Date?

    func clear() {
        token = nil
        expiresAt = nil
    }
}

// MARK: - KeychainItem

/// Low-level helper for reading, writing, and deleting a single generic-password Keychain entry
/// identified by service (`wc.Offload`) and a caller-supplied account name.
struct KeychainItem {
    private static let service = "wc.Offload"
    let account: String

    func read() -> Data? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Self.service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return data
    }

    @discardableResult
    func write(_ data: Data) -> Bool {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Self.service,
            kSecAttrAccount: account,
        ]
        let update: [CFString: Any] = [kSecValueData: data]
        let updateStatus = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var addItem = query
            addItem[kSecValueData] = data
            addItem[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let addStatus = SecItemAdd(addItem as CFDictionary, nil)
            if addStatus != errSecSuccess {
                AppLogger.persistence.error("Keychain add failed for \(self.account, privacy: .public): OSStatus \(addStatus, privacy: .public)")
                return false
            }
            return true
        } else if updateStatus != errSecSuccess {
            AppLogger.persistence.error("Keychain update failed for \(self.account, privacy: .public): OSStatus \(updateStatus, privacy: .public)")
            return false
        }
        return true
    }

    func delete() {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Self.service,
            kSecAttrAccount: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - KeychainSessionTokenStore

/// Persists anonymous backend session tokens in the iOS Keychain so they survive app termination.
/// Loads any previously stored token on initialization and writes to Keychain whenever both
/// token and expiry are set. Setting either property to `nil` removes the Keychain entry.
final class KeychainSessionTokenStore: SessionTokenStore {
    private static let keychainItem = KeychainItem(account: "anonymous_session_token")

    private struct Payload: Codable {
        let token: String
        let expiresAt: Date
    }

    private var _token: String?
    private var _expiresAt: Date?

    init() {
        if let payload = Self.loadPayload() {
            _token = payload.token
            _expiresAt = payload.expiresAt
        }
    }

    var token: String? {
        get { _token }
        set {
            _token = newValue
            if newValue == nil { Self.keychainItem.delete() } else { saveIfComplete() }
        }
    }

    var expiresAt: Date? {
        get { _expiresAt }
        set {
            _expiresAt = newValue
            if newValue == nil { Self.keychainItem.delete() } else { saveIfComplete() }
        }
    }

    /// Removes the stored token from memory and Keychain.
    func clear() {
        _token = nil
        _expiresAt = nil
        Self.keychainItem.delete()
    }

    // MARK: - Private

    private func saveIfComplete() {
        guard let token = _token, let expiresAt = _expiresAt else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(Payload(token: token, expiresAt: expiresAt)) else { return }
        Self.keychainItem.write(data)
    }

    private static func loadPayload() -> Payload? {
        guard let data = keychainItem.read() else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Payload.self, from: data)
    }
}
