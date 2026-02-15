// Purpose: Unit tests for backend client scaffolding.
// Authority: Code-level
// Governed by: AGENTS.md

@testable import Offload
import Foundation
import XCTest

final class AIBackendClientTests: XCTestCase {
    func testTokenExpiryRefreshesBeforeBreakdownCall() async throws {
        let transport = MockTransport()
        let tokenStore = InMemorySessionTokenStore()
        tokenStore.token = "stale-token"
        tokenStore.expiresAt = Date().addingTimeInterval(-30)

        let consent = StubConsentStore(isCloudAIEnabled: true)

        transport.enqueue(status: 200, jsonObject: [
            "session_token": "fresh-token",
            "expires_at": "2030-01-01T00:00:00Z",
        ])
        transport.enqueue(status: 200, jsonObject: [
            "steps": [["title": "Step 1", "substeps": []]],
            "provider": "openai",
            "latency_ms": 12,
            "usage": ["input_tokens": 1, "output_tokens": 2],
        ])

        let client = NetworkAIBackendClient(
            transport: transport,
            tokenStore: tokenStore,
            consentStore: consent,
            installIDProvider: { "install-12345" },
            appVersionProvider: { "1.0" },
            platformProvider: { "ios" }
        )

        let response = try await client.generateBreakdown(
            request: BreakdownGenerateRequest(
                inputText: "Clean kitchen",
                granularity: 2,
                contextHints: [],
                templateIds: []
            )
        )

        XCTAssertEqual(response.steps.first?.title, "Step 1")
        XCTAssertEqual(transport.sentRequests.count, 2)
        XCTAssertEqual(transport.sentRequests[0].path, "/v1/sessions/anonymous")
        XCTAssertEqual(transport.sentRequests[1].path, "/v1/ai/breakdown/generate")
        XCTAssertEqual(transport.sentRequests[1].headers["Authorization"], "Bearer fresh-token")
    }

    func testUnauthorizedBreakdownRetriesAfterSessionRefresh() async throws {
        let transport = MockTransport()
        let tokenStore = InMemorySessionTokenStore()
        tokenStore.token = "old-token"
        tokenStore.expiresAt = Date().addingTimeInterval(120)

        let consent = StubConsentStore(isCloudAIEnabled: true)

        transport.enqueue(status: 401, jsonObject: [
            "error": [
                "code": "invalid_token",
                "message": "Invalid session token",
                "request_id": "req-1",
            ],
        ])
        transport.enqueue(status: 200, jsonObject: [
            "session_token": "refreshed-token",
            "expires_at": "2030-01-01T00:00:00Z",
        ])
        transport.enqueue(status: 200, jsonObject: [
            "steps": [["title": "Step 2", "substeps": []]],
            "provider": "openai",
            "latency_ms": 20,
            "usage": ["input_tokens": 3, "output_tokens": 5],
        ])

        let client = NetworkAIBackendClient(
            transport: transport,
            tokenStore: tokenStore,
            consentStore: consent,
            installIDProvider: { "install-12345" },
            appVersionProvider: { "1.0" },
            platformProvider: { "ios" }
        )

        let response = try await client.generateBreakdown(
            request: BreakdownGenerateRequest(
                inputText: "Plan trip",
                granularity: 3,
                contextHints: [],
                templateIds: []
            )
        )

        XCTAssertEqual(response.steps.first?.title, "Step 2")
        XCTAssertEqual(transport.sentRequests.count, 3)
        XCTAssertEqual(transport.sentRequests[0].path, "/v1/ai/breakdown/generate")
        XCTAssertEqual(transport.sentRequests[1].path, "/v1/sessions/anonymous")
        XCTAssertEqual(transport.sentRequests[2].path, "/v1/ai/breakdown/generate")
        XCTAssertEqual(transport.sentRequests[2].headers["Authorization"], "Bearer refreshed-token")
    }

    func testConsentDisabledFailsClosed() async throws {
        let transport = MockTransport()
        let tokenStore = InMemorySessionTokenStore()
        tokenStore.token = "token"
        tokenStore.expiresAt = Date().addingTimeInterval(120)

        let client = NetworkAIBackendClient(
            transport: transport,
            tokenStore: tokenStore,
            consentStore: StubConsentStore(isCloudAIEnabled: false),
            installIDProvider: { "install-12345" },
            appVersionProvider: { "1.0" },
            platformProvider: { "ios" }
        )

        do {
            _ = try await client.generateBreakdown(
                request: BreakdownGenerateRequest(
                    inputText: "Do taxes",
                    granularity: 2,
                    contextHints: [],
                    templateIds: []
                )
            )
            XCTFail("Expected consentRequired error")
        } catch let error as AIBackendClientError {
            XCTAssertEqual(error, .consentRequired)
            XCTAssertTrue(transport.sentRequests.isEmpty)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private final class StubConsentStore: CloudAIConsentStore {
    var isCloudAIEnabled: Bool

    init(isCloudAIEnabled: Bool) {
        self.isCloudAIEnabled = isCloudAIEnabled
    }
}

private final class MockTransport: APITransporting {
    var sentRequests: [APIRequest] = []
    private var queuedResponses: [(Data, HTTPURLResponse)] = []

    func enqueue(status: Int, jsonObject: [String: Any]) {
        let data = try! JSONSerialization.data(withJSONObject: jsonObject)
        let response = HTTPURLResponse(
            url: URL(string: "https://api.offload.app")!,
            statusCode: status,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        queuedResponses.append((data, response))
    }

    func send(_ request: APIRequest) async throws -> (Data, HTTPURLResponse) {
        sentRequests.append(request)
        guard !queuedResponses.isEmpty else {
            throw APIClientError.invalidResponse
        }

        let next = queuedResponses.removeFirst()
        if (200 ... 299).contains(next.1.statusCode) {
            return next
        }
        throw APIClientError.statusCode(next.1.statusCode, next.0)
    }
}
