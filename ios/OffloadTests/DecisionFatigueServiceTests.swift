// Purpose: Unit tests for decision fatigue service orchestration.
// Authority: Code-level
// Governed by: CLAUDE.md

@testable import Offload
import XCTest

final class DecisionFatigueServiceTests: XCTestCase {

    // MARK: - Consent off

    func testConsentOffUsesOnDeviceFallback() async throws {
        let backend = MockDecisionBackendClient()
        let usage = TestDecisionUsageStore()
        let onDevice = StubOnDeviceDecisionGenerator(options: [
            DecisionOption(title: "Option A", description: "Offline fallback", isRecommended: true),
        ])
        let consent = TestDecisionConsentStore(isCloudAIEnabled: false)

        let service = DefaultDecisionFatigueService(
            backendClient: backend,
            consentStore: consent,
            usageStore: usage,
            onDeviceGenerator: onDevice,
            installIDProvider: { "install-12345" }
        )

        let result = try await service.suggestDecisions(
            inputText: "Should I use A or B?",
            contextHints: [],
            clarifyingAnswers: []
        )

        XCTAssertEqual(result.source, .onDevice)
        XCTAssertEqual(result.options.first?.title, "Option A")
        XCTAssertEqual(backend.suggestCalls, 0)
        XCTAssertEqual(usage.localCount(for: "decide"), 1)
    }

    // MARK: - Consent on

    func testConsentOnUsesCloudWhenAvailable() async throws {
        let backend = MockDecisionBackendClient()
        backend.suggestResult = .success(DecisionRecommendResponse(
            options: [
                DecisionOption(title: "Cloud Option A", description: "Best choice", isRecommended: true),
                DecisionOption(title: "Cloud Option B", description: "Alternative", isRecommended: false),
            ],
            clarifyingQuestions: ["What is your timeline?"],
            provider: "openai",
            latencyMs: 10,
            usage: DecisionUsage(inputTokens: 20, outputTokens: 40)
        ))

        let service = DefaultDecisionFatigueService(
            backendClient: backend,
            consentStore: TestDecisionConsentStore(isCloudAIEnabled: true),
            usageStore: TestDecisionUsageStore(),
            onDeviceGenerator: StubOnDeviceDecisionGenerator(options: []),
            installIDProvider: { "install-12345" }
        )

        let result = try await service.suggestDecisions(
            inputText: "Should I use A or B?",
            contextHints: [],
            clarifyingAnswers: []
        )

        XCTAssertEqual(result.source, .cloud)
        XCTAssertEqual(result.options.count, 2)
        XCTAssertEqual(result.options.first?.title, "Cloud Option A")
        XCTAssertEqual(result.clarifyingQuestions, ["What is your timeline?"])
        XCTAssertEqual(backend.suggestCalls, 1)
    }

    // MARK: - Fallback behaviour

    func testTransportFailureFallsBackToOnDevice() async throws {
        let backend = MockDecisionBackendClient()
        backend.suggestResult = .failure(AIBackendClientError.transport)

        let service = DefaultDecisionFatigueService(
            backendClient: backend,
            consentStore: TestDecisionConsentStore(isCloudAIEnabled: true),
            usageStore: TestDecisionUsageStore(),
            onDeviceGenerator: StubOnDeviceDecisionGenerator(options: [
                DecisionOption(title: "Fallback", description: "On-device", isRecommended: true),
            ]),
            installIDProvider: { "install-12345" }
        )

        let result = try await service.suggestDecisions(
            inputText: "Should I use A or B?",
            contextHints: [],
            clarifyingAnswers: []
        )

        XCTAssertEqual(result.source, .onDevice)
        XCTAssertEqual(result.options.first?.title, "Fallback")
        XCTAssertEqual(backend.suggestCalls, 1)
    }

    func testServerUnavailableFallsBackToOnDevice() async throws {
        let backend = MockDecisionBackendClient()
        backend.suggestResult = .failure(AIBackendClientError.server(code: "provider_unavailable", status: 503))

        let service = DefaultDecisionFatigueService(
            backendClient: backend,
            consentStore: TestDecisionConsentStore(isCloudAIEnabled: true),
            usageStore: TestDecisionUsageStore(),
            onDeviceGenerator: StubOnDeviceDecisionGenerator(options: [
                DecisionOption(title: "Fallback", description: "On-device", isRecommended: true),
            ]),
            installIDProvider: { "install-12345" }
        )

        let result = try await service.suggestDecisions(
            inputText: "A or B?",
            contextHints: [],
            clarifyingAnswers: []
        )

        XCTAssertEqual(result.source, .onDevice)
        XCTAssertEqual(backend.suggestCalls, 1)
    }

    func testPolicyErrorDoesNotFallback() async throws {
        let backend = MockDecisionBackendClient()
        backend.suggestResult = .failure(AIBackendClientError.server(code: "quota_exceeded", status: 429))

        let service = DefaultDecisionFatigueService(
            backendClient: backend,
            consentStore: TestDecisionConsentStore(isCloudAIEnabled: true),
            usageStore: TestDecisionUsageStore(),
            onDeviceGenerator: StubOnDeviceDecisionGenerator(options: []),
            installIDProvider: { "install-12345" }
        )

        do {
            _ = try await service.suggestDecisions(
                inputText: "A or B?",
                contextHints: [],
                clarifyingAnswers: []
            )
            XCTFail("Expected quota_exceeded to be surfaced")
        } catch let error as AIBackendClientError {
            XCTAssertEqual(error, .server(code: "quota_exceeded", status: 429))
            XCTAssertEqual(backend.suggestCalls, 1)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Usage tracking

    func testUsageIncrementedRegardlessOfSource() async throws {
        let usage = TestDecisionUsageStore()

        let consentOffService = DefaultDecisionFatigueService(
            backendClient: MockDecisionBackendClient(),
            consentStore: TestDecisionConsentStore(isCloudAIEnabled: false),
            usageStore: usage,
            onDeviceGenerator: StubOnDeviceDecisionGenerator(options: []),
            installIDProvider: { "install-12345" }
        )

        _ = try await consentOffService.suggestDecisions(inputText: "A?", contextHints: [], clarifyingAnswers: [])
        XCTAssertEqual(usage.localCount(for: "decide"), 1)
    }

    // MARK: - On-device generator

    func testOnDeviceGeneratorExtractsOrAlternatives() async throws {
        let generator = SimpleOnDeviceDecisionGenerator()

        let result = try await generator.suggestDecisions(
            inputText: "Should I use Postgres or SQLite?",
            contextHints: [],
            clarifyingAnswers: []
        )

        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result[0].title.contains("Postgres") || result[0].title.contains("Should I use"))
        XCTAssertTrue(result.contains(where: { $0.isRecommended }))
    }

    func testOnDeviceGeneratorFallsBackToGenericOptions() async throws {
        let generator = SimpleOnDeviceDecisionGenerator()

        let result = try await generator.suggestDecisions(
            inputText: "I need to figure out what to do with my project.",
            contextHints: [],
            clarifyingAnswers: []
        )

        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(result.contains(where: { $0.isRecommended }))
    }

    func testOnDeviceGeneratorReturnsAtLeastOneOption() async throws {
        let generator = SimpleOnDeviceDecisionGenerator()

        let result = try await generator.suggestDecisions(
            inputText: "x",
            contextHints: [],
            clarifyingAnswers: []
        )

        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains(where: { $0.isRecommended }))
    }
}

// MARK: - Test doubles

private final class MockDecisionBackendClient: AIBackendClient {
    var suggestResult: Result<DecisionRecommendResponse, Error> = .failure(AIBackendClientError.transport)

    private(set) var suggestCalls = 0

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
        BrainDumpCompileResponse(
            items: [],
            provider: "openai",
            latencyMs: 0,
            usage: BrainDumpUsage(inputTokens: 0, outputTokens: 0)
        )
    }

    func suggestDecisions(request _: DecisionRecommendRequest) async throws -> DecisionRecommendResponse {
        suggestCalls += 1
        return try suggestResult.get()
    }

    func signInWithApple(request _: AppleAuthRequest) async throws -> AppleAuthResponse {
        throw AIBackendClientError.transport
    }

    func reconcileUsage(request _: UsageReconcileRequest) async throws -> UsageReconcileResponse {
        throw AIBackendClientError.transport
    }
}

private final class TestDecisionConsentStore: CloudAIConsentStore {
    var isCloudAIEnabled: Bool

    init(isCloudAIEnabled: Bool) {
        self.isCloudAIEnabled = isCloudAIEnabled
    }
}

private final class TestDecisionUsageStore: UsageCounterStore {
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

private struct StubOnDeviceDecisionGenerator: OnDeviceDecisionGenerating {
    let options: [DecisionOption]

    func suggestDecisions(
        inputText _: String,
        contextHints _: [String],
        clarifyingAnswers _: [DecisionClarifyingAnswer]
    ) async throws -> [DecisionOption] {
        options
    }
}
