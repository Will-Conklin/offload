// Purpose: Unit tests for breakdown service orchestration.
// Authority: Code-level
// Governed by: AGENTS.md

@testable import Offload
import XCTest

final class BreakdownServiceTests: XCTestCase {
    func testConsentOffUsesOnDeviceFallback() async throws {
        let backend = MockBackendClient()
        backend.breakdownResult = .failure(AIBackendClientError.transport)

        let usage = TestUsageCounterStore()
        let onDevice = StubOnDeviceGenerator(steps: [BreakdownStep(title: "Offline step")])
        let consent = TestConsentStore(isCloudAIEnabled: false)

        let service = DefaultBreakdownService(
            backendClient: backend,
            consentStore: consent,
            usageStore: usage,
            onDeviceGenerator: onDevice,
            installIDProvider: { "install-12345" }
        )

        let result = try await service.generateBreakdown(
            inputText: "Organize office",
            granularity: 2,
            contextHints: [],
            templateIds: []
        )

        XCTAssertEqual(result.source, .onDevice)
        XCTAssertEqual(result.steps.first?.title, "Offline step")
        XCTAssertEqual(backend.generateCalls, 0)
        XCTAssertEqual(usage.localCount(for: "breakdown"), 1)
    }

    func testConsentOnUsesCloudWhenAvailable() async throws {
        let backend = MockBackendClient()
        backend.breakdownResult = .success(
            BreakdownGenerateResponse(
                steps: [BreakdownStep(title: "Cloud step")],
                provider: "openai",
                latencyMs: 10,
                usage: BreakdownUsage(inputTokens: 2, outputTokens: 3)
            )
        )

        let usage = TestUsageCounterStore()
        let consent = TestConsentStore(isCloudAIEnabled: true)

        let service = DefaultBreakdownService(
            backendClient: backend,
            consentStore: consent,
            usageStore: usage,
            onDeviceGenerator: StubOnDeviceGenerator(steps: [BreakdownStep(title: "Offline step")]),
            installIDProvider: { "install-12345" }
        )

        let result = try await service.generateBreakdown(
            inputText: "Plan launch",
            granularity: 3,
            contextHints: [],
            templateIds: []
        )

        XCTAssertEqual(result.source, .cloud)
        XCTAssertEqual(result.steps.first?.title, "Cloud step")
        XCTAssertEqual(backend.generateCalls, 1)
    }

    func testCloudFailureFallsBackToOnDevice() async throws {
        let backend = MockBackendClient()
        backend.breakdownResult = .failure(AIBackendClientError.transport)

        let service = DefaultBreakdownService(
            backendClient: backend,
            consentStore: TestConsentStore(isCloudAIEnabled: true),
            usageStore: TestUsageCounterStore(),
            onDeviceGenerator: StubOnDeviceGenerator(steps: [BreakdownStep(title: "Fallback step")]),
            installIDProvider: { "install-12345" }
        )

        let result = try await service.generateBreakdown(
            inputText: "Handle outage",
            granularity: 4,
            contextHints: [],
            templateIds: []
        )

        XCTAssertEqual(result.source, .onDevice)
        XCTAssertEqual(result.steps.first?.title, "Fallback step")
        XCTAssertEqual(backend.generateCalls, 1)
    }

    func testReconcileUsagePreservesMergedCounts() async throws {
        let backend = MockBackendClient()
        backend.reconcileResult = .success(
            UsageReconcileResponse(
                serverCount: 3,
                effectiveRemaining: 7,
                reconciledAt: .now
            )
        )

        let usage = TestUsageCounterStore()
        usage.increment(feature: "breakdown", by: 5)

        let service = DefaultBreakdownService(
            backendClient: backend,
            consentStore: TestConsentStore(isCloudAIEnabled: true),
            usageStore: usage,
            onDeviceGenerator: StubOnDeviceGenerator(steps: []),
            installIDProvider: { "install-12345" }
        )

        _ = try await service.reconcileUsage(feature: "breakdown")
        XCTAssertEqual(usage.mergedCount(for: "breakdown"), 5)

        backend.reconcileResult = .success(
            UsageReconcileResponse(
                serverCount: 7,
                effectiveRemaining: 3,
                reconciledAt: .now
            )
        )
        _ = try await service.reconcileUsage(feature: "breakdown")
        XCTAssertEqual(usage.mergedCount(for: "breakdown"), 7)
    }
}

private final class MockBackendClient: AIBackendClient {
    var breakdownResult: Result<BreakdownGenerateResponse, Error> = .failure(AIBackendClientError.transport)
    var reconcileResult: Result<UsageReconcileResponse, Error> = .failure(AIBackendClientError.transport)

    private(set) var generateCalls = 0

    func createAnonymousSession(request _: AnonymousSessionRequest) async throws -> AnonymousSessionResponse {
        AnonymousSessionResponse(sessionToken: "token", expiresAt: .distantFuture)
    }

    func generateBreakdown(request _: BreakdownGenerateRequest) async throws -> BreakdownGenerateResponse {
        generateCalls += 1
        return try breakdownResult.get()
    }

    func reconcileUsage(request _: UsageReconcileRequest) async throws -> UsageReconcileResponse {
        try reconcileResult.get()
    }
}

private final class TestConsentStore: CloudAIConsentStore {
    var isCloudAIEnabled: Bool

    init(isCloudAIEnabled: Bool) {
        self.isCloudAIEnabled = isCloudAIEnabled
    }
}

private final class TestUsageCounterStore: UsageCounterStore {
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

private struct StubOnDeviceGenerator: OnDeviceBreakdownGenerating {
    let steps: [BreakdownStep]

    func generateBreakdown(
        inputText _: String,
        granularity _: Int,
        contextHints _: [String],
        templateIds _: [String]
    ) async throws -> [BreakdownStep] {
        steps
    }
}
