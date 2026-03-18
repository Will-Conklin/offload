// Purpose: Unit tests for AuthManager and KeychainAuthStore.
// Authority: Code-level
// Governed by: CLAUDE.md

@testable import Offload
import Foundation
import XCTest

@MainActor
final class AuthManagerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        KeychainAuthStore.clear()
        // Also clear the session token store used in sign-in tests.
        KeychainSessionTokenStore().clear()
    }

    override func tearDown() {
        super.tearDown()
        KeychainAuthStore.clear()
        KeychainSessionTokenStore().clear()
    }

    // MARK: - KeychainAuthStore

    func testSaveAndLoadIdentity() {
        KeychainAuthStore.save(userId: "user-abc-123", displayName: "Alice")

        let loaded = KeychainAuthStore.load()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.userId, "user-abc-123")
        XCTAssertEqual(loaded?.displayName, "Alice")
    }

    func testSaveWithNilDisplayName() {
        KeychainAuthStore.save(userId: "user-no-name", displayName: nil)

        let loaded = KeychainAuthStore.load()
        XCTAssertEqual(loaded?.userId, "user-no-name")
        XCTAssertNil(loaded?.displayName)
    }

    func testClearRemovesIdentity() {
        KeychainAuthStore.save(userId: "user-to-clear", displayName: nil)
        KeychainAuthStore.clear()
        XCTAssertNil(KeychainAuthStore.load())
    }

    func testOverwriteUpdatesIdentity() {
        KeychainAuthStore.save(userId: "user-old", displayName: "Old Name")
        KeychainAuthStore.save(userId: "user-new", displayName: "New Name")

        XCTAssertEqual(KeychainAuthStore.load()?.userId, "user-new")
    }

    // MARK: - AuthManager initial state

    func testAuthManagerStartsAnonymous() {
        let manager = AuthManager()
        XCTAssertEqual(manager.authState, .anonymous)
    }

    func testAuthManagerRestoresAuthenticatedStateFromKeychain() {
        KeychainAuthStore.save(userId: "restored-user", displayName: "Bob")
        let manager = AuthManager()
        XCTAssertEqual(manager.authState, .authenticated(userId: "restored-user", displayName: "Bob"))
    }

    // MARK: - signInWithApple

    func testSignInSetsAuthenticatedState() async throws {
        let transport = StubTransport()
        transport.enqueue(status: 200, jsonObject: [
            "session_token": "auth-session-token",
            "expires_at": "2030-01-01T00:00:00Z",
            "user_id": "srv-user-456",
        ])
        let client = NetworkAIBackendClient(
            transport: transport,
            tokenStore: KeychainSessionTokenStore(),
            consentStore: StubConsentStore(isCloudAIEnabled: false),
            installIDProvider: { "install-test" },
            appVersionProvider: { "1.0" },
            platformProvider: { "ios" }
        )

        let manager = AuthManager()
        try await manager.signInWithApple(
            identityToken: "fake-apple-token",
            installId: "install-test",
            displayName: "Carol",
            using: client
        )

        XCTAssertEqual(manager.authState, .authenticated(userId: "srv-user-456", displayName: "Carol"))
        XCTAssertEqual(KeychainAuthStore.load()?.userId, "srv-user-456")
    }

    func testSignInPersistsSessionTokenToKeychain() async throws {
        let transport = StubTransport()
        transport.enqueue(status: 200, jsonObject: [
            "session_token": "persisted-auth-token",
            "expires_at": "2030-06-01T00:00:00Z",
            "user_id": "srv-user-789",
        ])
        let tokenStore = KeychainSessionTokenStore()
        let client = NetworkAIBackendClient(
            transport: transport,
            tokenStore: tokenStore,
            consentStore: StubConsentStore(isCloudAIEnabled: false),
            installIDProvider: { "install-test" },
            appVersionProvider: { "1.0" },
            platformProvider: { "ios" }
        )

        let manager = AuthManager()
        try await manager.signInWithApple(
            identityToken: "apple-token",
            installId: "install-test",
            displayName: nil,
            using: client
        )

        XCTAssertEqual(tokenStore.token, "persisted-auth-token")
    }

    // MARK: - signOut

    func testSignOutResetsToAnonymous() {
        KeychainAuthStore.save(userId: "signed-in-user", displayName: nil)
        let manager = AuthManager()

        manager.signOut()

        XCTAssertEqual(manager.authState, .anonymous)
        XCTAssertNil(KeychainAuthStore.load())
    }
}

// MARK: - Test Helpers

private final class StubConsentStore: CloudAIConsentStore {
    var isCloudAIEnabled: Bool
    init(isCloudAIEnabled: Bool) { self.isCloudAIEnabled = isCloudAIEnabled }
}

private final class StubTransport: APITransporting {
    var sentRequests: [APIRequest] = []
    private var queue: [(Data, HTTPURLResponse)] = []

    func enqueue(status: Int, jsonObject: [String: Any]) {
        let data = try! JSONSerialization.data(withJSONObject: jsonObject)
        let response = HTTPURLResponse(
            url: URL(string: "https://api.offload.app")!,
            statusCode: status,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        queue.append((data, response))
    }

    func send(_ request: APIRequest) async throws -> (Data, HTTPURLResponse) {
        sentRequests.append(request)
        guard !queue.isEmpty else { throw APIClientError.invalidResponse }
        let next = queue.removeFirst()
        if (200...299).contains(next.1.statusCode) { return next }
        throw APIClientError.statusCode(next.1.statusCode, next.0)
    }
}
