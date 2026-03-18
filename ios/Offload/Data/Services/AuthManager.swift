// Purpose: Manages optional Apple Sign In identity state for the app.
// Authority: Code-level
// Governed by: CLAUDE.md

import Foundation

// MARK: - Auth State

enum AuthState: Equatable {
    case anonymous
    case authenticated(userId: String, displayName: String?)
}

// MARK: - Keychain Auth Store

/// Stores the authenticated user identity (userId, displayName) in the Keychain.
/// Separate from KeychainSessionTokenStore, which holds the backend session token.
enum KeychainAuthStore {
    private static let item = KeychainItem(account: "apple_auth_identity")

    struct Identity: Codable {
        let userId: String
        let displayName: String?
    }

    static func save(userId: String, displayName: String?) {
        let identity = Identity(userId: userId, displayName: displayName)
        guard let data = try? JSONEncoder().encode(identity) else { return }
        item.write(data)
    }

    static func load() -> Identity? {
        guard let data = item.read() else { return nil }
        return try? JSONDecoder().decode(Identity.self, from: data)
    }

    static func clear() {
        item.delete()
    }
}

// MARK: - AuthManager

/// Manages optional Sign In with Apple state. The anonymous path is always available;
/// signing in provides a stable Apple-ID-backed identity tied to the backend session.
@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published private(set) var authState: AuthState

    init() {
        if let identity = KeychainAuthStore.load() {
            authState = .authenticated(userId: identity.userId, displayName: identity.displayName)
        } else {
            authState = .anonymous
        }
    }

    /// Exchange an Apple identity token for an Offload authenticated session.
    ///
    /// - Parameters:
    ///   - identityToken: The raw identity token string from `ASAuthorizationAppleIDCredential.identityToken`.
    ///   - installId: The device install ID used to link any existing usage history.
    ///   - displayName: User-provided display name (only present on first Apple sign-in).
    ///   - client: The backend client used to call `POST /v1/auth/apple`.
    func signInWithApple(
        identityToken: String,
        installId: String,
        displayName: String?,
        using client: AIBackendClient
    ) async throws {
        let request = AppleAuthRequest(
            appleIdentityToken: identityToken,
            installId: installId,
            displayName: displayName
        )
        let response = try await client.signInWithApple(request: request)
        KeychainAuthStore.save(userId: response.userId, displayName: displayName)
        authState = .authenticated(userId: response.userId, displayName: displayName)
    }

    /// Signs out and resets to anonymous state, clearing all stored identity from Keychain.
    func signOut() {
        KeychainAuthStore.clear()
        authState = .anonymous
    }
}
