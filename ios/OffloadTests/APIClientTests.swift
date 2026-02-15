// Purpose: Unit tests for API client URL resolution.
// Authority: Code-level
// Governed by: AGENTS.md

@testable import Offload
import Foundation
import XCTest

final class APIClientTests: XCTestCase {
    func testResolvedURLPreservesBasePathPrefixForLeadingSlashPath() {
        let client = APIClient(
            session: URLSession(configuration: .ephemeral),
            baseURL: URL(string: "https://api.offload.app/api")!
        )

        let resolved = client.resolvedURL(for: "/v1/health")
        XCTAssertEqual(resolved?.absoluteString, "https://api.offload.app/api/v1/health")
    }

    func testResolvedURLPreservesBasePathPrefixAndQuery() {
        let client = APIClient(
            session: URLSession(configuration: .ephemeral),
            baseURL: URL(string: "https://api.offload.app/api/")!
        )

        let resolved = client.resolvedURL(for: "/v1/usage/reconcile?feature=breakdown")
        XCTAssertEqual(
            resolved?.absoluteString,
            "https://api.offload.app/api/v1/usage/reconcile?feature=breakdown"
        )
    }
}
