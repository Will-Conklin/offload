// Purpose: Keychain-backed session token store for anonymous backend sessions.
// Authority: Code-level
// Governed by: CLAUDE.md

import Foundation
import Security

/// Persists anonymous backend session tokens in the iOS Keychain so they survive app termination.
/// Loads any previously stored token on initialization and writes to Keychain whenever both
/// token and expiry are set. Setting either property to `nil` removes the Keychain entry.
final class KeychainSessionTokenStore: SessionTokenStore {
    private enum Key {
        static let service = "wc.Offload"
        static let account = "anonymous_session_token"
    }

    private struct Payload: Codable {
        let token: String
        let expiresAt: Date
    }

    private var _token: String?
    private var _expiresAt: Date?

    init() {
        if let payload = Self.load() {
            _token = payload.token
            _expiresAt = payload.expiresAt
        }
    }

    var token: String? {
        get { _token }
        set {
            _token = newValue
            if newValue == nil { Self.delete() } else { saveIfComplete() }
        }
    }

    var expiresAt: Date? {
        get { _expiresAt }
        set {
            _expiresAt = newValue
            if newValue == nil { Self.delete() } else { saveIfComplete() }
        }
    }

    /// Removes the stored token from memory and Keychain.
    func clear() {
        _token = nil
        _expiresAt = nil
        Self.delete()
    }

    // MARK: - Private

    private func saveIfComplete() {
        guard let token = _token, let expiresAt = _expiresAt else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(Payload(token: token, expiresAt: expiresAt)) else { return }
        Self.save(data: data)
    }

    private static func load() -> Payload? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Key.service,
            kSecAttrAccount: Key.account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(Payload.self, from: data)
    }

    private static func save(data: Data) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Key.service,
            kSecAttrAccount: Key.account,
        ]
        let update: [CFString: Any] = [kSecValueData: data]
        if SecItemUpdate(query as CFDictionary, update as CFDictionary) == errSecItemNotFound {
            var addItem = query
            addItem[kSecValueData] = data
            addItem[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            SecItemAdd(addItem as CFDictionary, nil)
        }
    }

    private static func delete() {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: Key.service,
            kSecAttrAccount: Key.account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
