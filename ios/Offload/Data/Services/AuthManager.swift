// Purpose: Sign in with Apple lifecycle management and credential persistence.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Credentials stored in iOS Keychain; restore on launch.

import AuthenticationServices
import Combine
import Foundation
import Security

/// Represents an authenticated Apple ID user with optional profile fields.
///
/// Apple only provides `fullName` and `email` on the first sign-in; subsequent
/// authorizations return only the `userId`. Persisted values are read from the Keychain.
struct AppleUser {
    let userId: String
    let fullName: String?
    let email: String?
}

/// Tracks the current authentication lifecycle phase.
enum AuthState {
    case signedOut
    case signingIn
    case signedIn(AppleUser)
}

/// Manages Sign in with Apple authentication state, persisting credentials in the Keychain.
///
/// On launch, call `restoreSession()` to check whether the stored Apple ID credential
/// is still authorized. After a successful `ASAuthorizationAppleIDCredential` result,
/// call `handleSignInResult(credential:)` to persist the user and transition to `.signedIn`.
@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var state: AuthState = .signedOut

    private let keychainService = "wc.Offload.auth"
    private let userIdKey = "apple_user_id"
    private let fullNameKey = "apple_full_name"
    private let emailKey = "apple_email"

    /// Attempts to restore a previously authenticated session from the Keychain.
    ///
    /// Checks the stored Apple ID credential state with Apple's servers. Transitions
    /// to `.signedIn` if authorized, or `.signedOut` if revoked/not found.
    func restoreSession() async {
        guard let userId = readKeychain(key: userIdKey) else { return }
        let credentialState = await checkCredentialState(userId: userId)
        switch credentialState {
        case .authorized:
            let user = AppleUser(
                userId: userId,
                fullName: readKeychain(key: fullNameKey),
                email: readKeychain(key: emailKey)
            )
            state = .signedIn(user)
        case .revoked, .notFound:
            clearKeychain()
            state = .signedOut
        default:
            state = .signedOut
        }
    }

    /// Persists the Apple ID credential and transitions to `.signedIn`.
    ///
    /// - Parameter credential: The credential returned by `ASAuthorizationController`.
    ///   Apple only provides `fullName` and `email` on the initial sign-in; on subsequent
    ///   authorizations these fields are `nil`, so previously stored values are used.
    func handleSignInResult(credential: ASAuthorizationAppleIDCredential) {
        let userId = credential.user
        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        let email = credential.email

        saveKeychain(key: userIdKey, value: userId)
        if !fullName.isEmpty { saveKeychain(key: fullNameKey, value: fullName) }
        if let email { saveKeychain(key: emailKey, value: email) }

        let user = AppleUser(
            userId: userId,
            fullName: fullName.isEmpty ? readKeychain(key: fullNameKey) : fullName,
            email: email ?? readKeychain(key: emailKey)
        )
        state = .signedIn(user)
    }

    /// Extracts the JWT identity token string from an Apple ID credential.
    ///
    /// - Parameter credential: The credential containing the identity token data.
    /// - Returns: The UTF-8 decoded token string, or `nil` if unavailable.
    func identityToken(from credential: ASAuthorizationAppleIDCredential) -> String? {
        guard let data = credential.identityToken else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Signs out by clearing all stored credentials and transitioning to `.signedOut`.
    func signOut() {
        clearKeychain()
        state = .signedOut
    }

    /// The currently signed-in user, or `nil` if not authenticated.
    var currentUser: AppleUser? {
        if case .signedIn(let user) = state { return user }
        return nil
    }

    /// Whether the user is currently signed in.
    var isSignedIn: Bool {
        if case .signedIn = state { return true }
        return false
    }

    // MARK: - Private Keychain helpers

    private func saveKeychain(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData as String] = data
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    private func readKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func clearKeychain() {
        deleteKeychain(key: userIdKey)
        deleteKeychain(key: fullNameKey)
        deleteKeychain(key: emailKey)
    }

    private func deleteKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(query as CFDictionary)
    }

    /// Checks the credential state for the given Apple user ID with Apple's servers.
    ///
    /// - Parameter userId: The Apple user identifier to verify.
    /// - Returns: The current credential state from `ASAuthorizationAppleIDProvider`.
    private func checkCredentialState(userId: String) async -> ASAuthorizationAppleIDProvider.CredentialState {
        await withCheckedContinuation { continuation in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userId) { state, _ in
                continuation.resume(returning: state)
            }
        }
    }
}
