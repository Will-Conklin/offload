// Purpose: Unit tests for SupportNudgeEvaluator and HomeViewModel nudge integration.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Keep tests deterministic and avoid relying on network or time.

@testable import Offload
import SwiftData
import XCTest

@MainActor
final class SupportNudgeEvaluatorTests: XCTestCase {
    // MARK: - RulesBasedNudgeEvaluator

    func testRulesBasedEvaluator_belowThreshold_returnsNil() async {
        let evaluator = RulesBasedNudgeEvaluator()
        let signals = SupportNudgeSignals(totalUncompleted: 14, capturedThisWeek: 5, completedThisWeek: 1)
        let result = await evaluator.evaluate(signals)
        XCTAssertNil(result, "No nudge should appear below the threshold")
    }

    func testRulesBasedEvaluator_atThreshold_returnsMessage() async {
        let evaluator = RulesBasedNudgeEvaluator()
        let signals = SupportNudgeSignals(totalUncompleted: 15, capturedThisWeek: 10, completedThisWeek: 0)
        let result = await evaluator.evaluate(signals)
        XCTAssertNotNil(result, "Nudge should appear at the threshold")
        XCTAssertFalse(result?.headline.isEmpty ?? true)
        XCTAssertFalse(result?.body.isEmpty ?? true)
    }

    func testRulesBasedEvaluator_aboveThreshold_returnsMessage() async {
        let evaluator = RulesBasedNudgeEvaluator()
        let signals = SupportNudgeSignals(totalUncompleted: 30, capturedThisWeek: 20, completedThisWeek: 2)
        let result = await evaluator.evaluate(signals)
        XCTAssertNotNil(result)
    }

    func testRulesBasedEvaluator_threshold_isCorrectValue() {
        XCTAssertEqual(RulesBasedNudgeEvaluator.threshold, 15)
    }

    // MARK: - HomeViewModel evaluator injection

    func testHomeViewModel_usesInjectedEvaluator() async throws {
        let schema = Schema([Item.self, Collection.self, CollectionItem.self, Tag.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let itemRepository = ItemRepository(modelContext: context)
        let collectionRepository = CollectionRepository(modelContext: context)

        let fixedMessage = SupportNudgeMessage(headline: "Test headline", body: "Test body")
        let mockEvaluator = MockNudgeEvaluator(message: fixedMessage)

        let viewModel = HomeViewModel(nudgeEvaluator: mockEvaluator)
        try await viewModel.loadStats(using: itemRepository, collectionRepository: collectionRepository)

        XCTAssertNotNil(viewModel.supportNudgeMessage)
        XCTAssertEqual(viewModel.supportNudgeMessage?.headline, "Test headline")
        XCTAssertEqual(viewModel.supportNudgeMessage?.body, "Test body")
        XCTAssertTrue(mockEvaluator.wasCalled)
    }

    func testHomeViewModel_evaluatorReceivesCorrectSignals() async throws {
        let schema = Schema([Item.self, Collection.self, CollectionItem.self, Tag.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        let itemRepository = ItemRepository(modelContext: context)
        let collectionRepository = CollectionRepository(modelContext: context)

        // Add some items: 3 total, 1 completed
        let item1 = try itemRepository.create(content: "Item 1")
        let item2 = try itemRepository.create(content: "Item 2")
        let item3 = try itemRepository.create(content: "Item 3")
        item3.completedAt = Date()
        try context.save()
        _ = item1; _ = item2

        let capturingEvaluator = CapturingNudgeEvaluator()
        let viewModel = HomeViewModel(nudgeEvaluator: capturingEvaluator)
        try await viewModel.loadStats(using: itemRepository, collectionRepository: collectionRepository)

        XCTAssertEqual(capturingEvaluator.capturedSignals?.totalUncompleted, 2)
    }
}

// MARK: - Test Doubles

@MainActor
private final class MockNudgeEvaluator: SupportNudgeEvaluating {
    let message: SupportNudgeMessage?
    private(set) var wasCalled = false

    init(message: SupportNudgeMessage?) {
        self.message = message
    }

    func evaluate(_ signals: SupportNudgeSignals) async -> SupportNudgeMessage? {
        wasCalled = true
        return message
    }
}

@MainActor
private final class CapturingNudgeEvaluator: SupportNudgeEvaluating {
    private(set) var capturedSignals: SupportNudgeSignals?

    func evaluate(_ signals: SupportNudgeSignals) async -> SupportNudgeMessage? {
        capturedSignals = signals
        return nil
    }
}
