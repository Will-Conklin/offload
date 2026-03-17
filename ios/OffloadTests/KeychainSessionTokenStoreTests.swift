// Purpose: Unit tests for KeychainSessionTokenStore.
// Authority: Code-level
// Governed by: CLAUDE.md

@testable import Offload
import XCTest

final class KeychainSessionTokenStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Ensure clean state before each test.
        KeychainSessionTokenStore().clear()
    }

    override func tearDown() {
        super.tearDown()
        KeychainSessionTokenStore().clear()
    }

    func testStoreAndRetrieveToken() {
        let store = KeychainSessionTokenStore()
        let expiry = Date(timeIntervalSinceNow: 3600)
        store.token = "test-token"
        store.expiresAt = expiry

        XCTAssertEqual(store.token, "test-token")
        XCTAssertEqual(store.expiresAt?.timeIntervalSince1970, expiry.timeIntervalSince1970, accuracy: 1)
    }

    func testPersistsAcrossInstances() {
        let expiry = Date(timeIntervalSinceNow: 3600)
        let store1 = KeychainSessionTokenStore()
        store1.token = "persisted-token"
        store1.expiresAt = expiry

        let store2 = KeychainSessionTokenStore()
        XCTAssertEqual(store2.token, "persisted-token")
        XCTAssertEqual(store2.expiresAt?.timeIntervalSince1970, expiry.timeIntervalSince1970, accuracy: 1)
    }

    func testClearRemovesTokenFromMemoryAndKeychain() {
        let store = KeychainSessionTokenStore()
        store.token = "to-clear"
        store.expiresAt = Date(timeIntervalSinceNow: 3600)

        store.clear()

        XCTAssertNil(store.token)
        XCTAssertNil(store.expiresAt)

        // New instance should also see nothing.
        let fresh = KeychainSessionTokenStore()
        XCTAssertNil(fresh.token)
        XCTAssertNil(fresh.expiresAt)
    }

    func testSettingTokenNilClearsKeychain() {
        let store = KeychainSessionTokenStore()
        store.token = "some-token"
        store.expiresAt = Date(timeIntervalSinceNow: 3600)

        store.token = nil

        let fresh = KeychainSessionTokenStore()
        XCTAssertNil(fresh.token)
        XCTAssertNil(fresh.expiresAt)
    }

    func testPartialSetDoesNotPersist() {
        // Setting only token (no expiry) must not persist to Keychain.
        let store = KeychainSessionTokenStore()
        store.token = "partial-token"
        // expiresAt never set

        let fresh = KeychainSessionTokenStore()
        XCTAssertNil(fresh.token)
    }

    func testOverwriteUpdatesKeychain() {
        let store = KeychainSessionTokenStore()
        store.token = "original-token"
        store.expiresAt = Date(timeIntervalSinceNow: 1800)

        store.token = "updated-token"
        store.expiresAt = Date(timeIntervalSinceNow: 7200)

        let fresh = KeychainSessionTokenStore()
        XCTAssertEqual(fresh.token, "updated-token")
    }
}
