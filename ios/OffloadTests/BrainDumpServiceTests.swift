// Purpose: Unit tests for brain dump service orchestration.
// Authority: Code-level
// Governed by: CLAUDE.md

@testable import Offload
import XCTest

final class BrainDumpServiceTests: XCTestCase {
    func testConsentOffUsesOnDeviceFallback() async throws {
        let backend = MockBrainDumpBackendClient()
        let usage = TestBrainDumpUsageStore()
        let onDevice = StubOnDeviceBrainDumpGenerator(items: [
            BrainDumpItem(title: "Offline item", type: "note"),
        ])
        let consent = TestBrainDumpConsentStore(isCloudAIEnabled: false)

        let service = DefaultBrainDumpService(
            backendClient: backend,
            consentStore: consent,
            usageStore: usage,
            onDeviceGenerator: onDevice,
            installIDProvider: { "install-12345" }
        )

        let result = try await service.compileBrainDump(inputText: "Long text here", contextHints: [])

        XCTAssertEqual(result.source, .onDevice)
        XCTAssertEqual(result.items.first?.title, "Offline item")
        XCTAssertEqual(backend.compileCalls, 0)
        XCTAssertEqual(usage.localCount(for: "braindump"), 1)
    }

    func testConsentOnUsesCloudWhenAvailable() async throws {
        let backend = MockBrainDumpBackendClient()
        backend.compileResult = .success(BrainDumpCompileResponse(
            items: [BrainDumpItem(title: "Cloud item", type: "task")],
            provider: "openai",
            latencyMs: 10,
            usage: BrainDumpUsage(inputTokens: 5, outputTokens: 8)
        ))

        let service = DefaultBrainDumpService(
            backendClient: backend,
            consentStore: TestBrainDumpConsentStore(isCloudAIEnabled: true),
            usageStore: TestBrainDumpUsageStore(),
            onDeviceGenerator: StubOnDeviceBrainDumpGenerator(items: []),
            installIDProvider: { "install-12345" }
        )

        let result = try await service.compileBrainDump(inputText: "Long capture", contextHints: [])

        XCTAssertEqual(result.source, .cloud)
        XCTAssertEqual(result.items.first?.title, "Cloud item")
        XCTAssertEqual(backend.compileCalls, 1)
    }

    func testCloudFailureFallsBackToOnDevice() async throws {
        let backend = MockBrainDumpBackendClient()
        backend.compileResult = .failure(AIBackendClientError.transport)

        let service = DefaultBrainDumpService(
            backendClient: backend,
            consentStore: TestBrainDumpConsentStore(isCloudAIEnabled: true),
            usageStore: TestBrainDumpUsageStore(),
            onDeviceGenerator: StubOnDeviceBrainDumpGenerator(items: [
                BrainDumpItem(title: "Fallback item", type: "note"),
            ]),
            installIDProvider: { "install-12345" }
        )

        let result = try await service.compileBrainDump(inputText: "Long capture", contextHints: [])

        XCTAssertEqual(result.source, .onDevice)
        XCTAssertEqual(result.items.first?.title, "Fallback item")
        XCTAssertEqual(backend.compileCalls, 1)
    }

    func testTransientServerFailureFallsBackToOnDevice() async throws {
        let backend = MockBrainDumpBackendClient()
        backend.compileResult = .failure(AIBackendClientError.server(code: "provider_unavailable", status: 503))

        let service = DefaultBrainDumpService(
            backendClient: backend,
            consentStore: TestBrainDumpConsentStore(isCloudAIEnabled: true),
            usageStore: TestBrainDumpUsageStore(),
            onDeviceGenerator: StubOnDeviceBrainDumpGenerator(items: [
                BrainDumpItem(title: "Fallback item", type: "note"),
            ]),
            installIDProvider: { "install-12345" }
        )

        let result = try await service.compileBrainDump(inputText: "Long capture", contextHints: [])

        XCTAssertEqual(result.source, .onDevice)
        XCTAssertEqual(backend.compileCalls, 1)
    }

    func testPolicyErrorDoesNotFallbackToOnDevice() async throws {
        let backend = MockBrainDumpBackendClient()
        backend.compileResult = .failure(AIBackendClientError.server(code: "quota_exceeded", status: 429))

        let service = DefaultBrainDumpService(
            backendClient: backend,
            consentStore: TestBrainDumpConsentStore(isCloudAIEnabled: true),
            usageStore: TestBrainDumpUsageStore(),
            onDeviceGenerator: StubOnDeviceBrainDumpGenerator(items: []),
            installIDProvider: { "install-12345" }
        )

        do {
            _ = try await service.compileBrainDump(inputText: "Long capture", contextHints: [])
            XCTFail("Expected quota_exceeded to be surfaced")
        } catch let error as AIBackendClientError {
            XCTAssertEqual(error, .server(code: "quota_exceeded", status: 429))
            XCTAssertEqual(backend.compileCalls, 1)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private final class MockBrainDumpBackendClient: AIBackendClient {
    var compileResult: Result<BrainDumpCompileResponse, Error> = .failure(AIBackendClientError.transport)

    private(set) var compileCalls = 0

    func createAnonymousSession(request _: AnonymousSessionRequest) async throws -> AnonymousSessionResponse {
        AnonymousSessionResponse(sessionToken: "token", expiresAt: .distantFuture)
    }

    func generateBreakdown(request _: BreakdownGenerateRequest) async throws -> BreakdownGenerateResponse {
        BreakdownGenerateResponse(
            steps: [],
            provider: "openai",
            latencyMs: 0,
            usage: BreakdownUsage(inputTokens: 0, outputTokens: 0)
        )
    }

    func compileBrainDump(request _: BrainDumpCompileRequest) async throws -> BrainDumpCompileResponse {
        compileCalls += 1
        return try compileResult.get()
    }

    func suggestDecisions(request _: DecisionRecommendRequest) async throws -> DecisionRecommendResponse {
        throw AIBackendClientError.transport
    }

    func signInWithApple(request _: AppleAuthRequest) async throws -> AppleAuthResponse {
        throw AIBackendClientError.transport
    }

    func reconcileUsage(request _: UsageReconcileRequest) async throws -> UsageReconcileResponse {
        throw AIBackendClientError.transport
    }
}

private final class TestBrainDumpConsentStore: CloudAIConsentStore {
    var isCloudAIEnabled: Bool

    init(isCloudAIEnabled: Bool) {
        self.isCloudAIEnabled = isCloudAIEnabled
    }
}

private final class TestBrainDumpUsageStore: UsageCounterStore {
    private var local: [String: Int] = [:]
    private var server: [String: Int] = [:]

    func increment(feature: String, by amount: Int) {
        local[feature, default: 0] += amount
    }

    func localCount(for feature: String) -> Int {
        local[feature, default: 0]
    }

    func mergedCount(for feature: String) -> Int {
        max(local[feature, default: 0], server[feature, default: 0])
    }

    func updateServerCount(feature: String, serverCount: Int) {
        let existing = server[feature, default: 0]
        server[feature] = max(existing, serverCount)
    }
}

private struct StubOnDeviceBrainDumpGenerator: OnDeviceBrainDumpGenerating {
    let items: [BrainDumpItem]

    func compileBrainDump(
        inputText _: String,
        contextHints _: [String]
    ) async throws -> [BrainDumpItem] {
        items
    }
}
