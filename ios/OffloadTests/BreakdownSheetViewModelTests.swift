// Purpose: Unit tests for BreakdownSheetViewModel.
// Authority: Code-level
// Governed by: CLAUDE.md

@testable import Offload
import XCTest

// MARK: - Stubs

private final class StubBreakdownService: BreakdownService {
    var stubbedResult: Result<BreakdownExecutionResult, Error> = .success(
        BreakdownExecutionResult(
            steps: [BreakdownStep(title: "Step A"), BreakdownStep(title: "Step B")],
            source: .onDevice,
            usage: nil
        )
    )
    var generateCallCount = 0
    var lastGranularity: Int?

    func generateBreakdown(
        inputText: String,
        granularity: Int,
        contextHints: [String],
        templateIds: [String]
    ) async throws -> BreakdownExecutionResult {
        generateCallCount += 1
        lastGranularity = granularity
        switch stubbedResult {
        case .success(let result): return result
        case .failure(let error): throw error
        }
    }

    func reconcileUsage(feature: String) async throws -> UsageReconcileResponse? { nil }
}

// MARK: - Tests

@MainActor
final class BreakdownSheetViewModelTests: XCTestCase {

    // MARK: - Phase management

    func testInitialPhaseIsConfigure() {
        let vm = BreakdownSheetViewModel()
        XCTAssertEqual(vm.phase, .configure)
    }

    func testGenerateSetsPhaseToPreview() async throws {
        let vm = BreakdownSheetViewModel()
        let service = StubBreakdownService()

        try await vm.generate(inputText: "Clean the garage", using: service)

        XCTAssertEqual(vm.phase, .preview)
    }

    // MARK: - Step population

    func testGeneratePopulatesStepsFromService() async throws {
        let vm = BreakdownSheetViewModel()
        let service = StubBreakdownService()
        service.stubbedResult = .success(BreakdownExecutionResult(
            steps: [BreakdownStep(title: "First"), BreakdownStep(title: "Second"), BreakdownStep(title: "Third")],
            source: .onDevice,
            usage: nil
        ))

        try await vm.generate(inputText: "Build a bookshelf", using: service)

        XCTAssertEqual(vm.steps.count, 3)
        XCTAssertEqual(vm.steps[0].title, "First")
        XCTAssertEqual(vm.steps[1].title, "Second")
        XCTAssertEqual(vm.steps[2].title, "Third")
    }

    func testGeneratePassesGranularityToService() async throws {
        let vm = BreakdownSheetViewModel()
        vm.granularity = 5
        let service = StubBreakdownService()

        try await vm.generate(inputText: "Any task", using: service)

        XCTAssertEqual(service.lastGranularity, 5)
    }

    // MARK: - Plan name derivation

    func testGenerateDerivesDefaultPlanNameFromInputText() async throws {
        let vm = BreakdownSheetViewModel()
        let service = StubBreakdownService()

        try await vm.generate(inputText: "Organize the home office", using: service)

        XCTAssertFalse(vm.planName.isEmpty)
        XCTAssertTrue(vm.planName.contains("Organize"))
    }

    func testGeneratePreservesExistingPlanNameIfSet() async throws {
        let vm = BreakdownSheetViewModel()
        vm.planName = "My custom plan"
        let service = StubBreakdownService()

        try await vm.generate(inputText: "Something else", using: service)

        XCTAssertEqual(vm.planName, "My custom plan")
    }

    // MARK: - Loading state

    func testIsGeneratingFalseAfterCompletion() async throws {
        let vm = BreakdownSheetViewModel()
        let service = StubBreakdownService()

        XCTAssertFalse(vm.isGenerating)
        try await vm.generate(inputText: "Task", using: service)
        XCTAssertFalse(vm.isGenerating)
    }

    // MARK: - Error propagation

    func testGeneratePropagatesServiceErrors() async {
        let vm = BreakdownSheetViewModel()
        let service = StubBreakdownService()
        service.stubbedResult = .failure(AIBackendClientError.transport)

        do {
            try await vm.generate(inputText: "Task", using: service)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(vm.phase, .configure, "Phase should remain .configure on failure")
        }
    }

    // MARK: - Step editing

    func testStepsAreEditable() async throws {
        let vm = BreakdownSheetViewModel()
        let service = StubBreakdownService()

        try await vm.generate(inputText: "Task", using: service)

        vm.steps[0].title = "Edited step title"
        XCTAssertEqual(vm.steps[0].title, "Edited step title")
    }

    // MARK: - isPlanNameEmpty

    func testIsPlanNameEmptyTrueWhenBlank() {
        let vm = BreakdownSheetViewModel()
        XCTAssertTrue(vm.isPlanNameEmpty)
    }

    func testIsPlanNameEmptyTrueForWhitespaceOnly() {
        let vm = BreakdownSheetViewModel()
        vm.planName = "   "
        XCTAssertTrue(vm.isPlanNameEmpty)
    }

    func testIsPlanNameEmptyFalseWhenNonEmpty() {
        let vm = BreakdownSheetViewModel()
        vm.planName = "My Plan"
        XCTAssertFalse(vm.isPlanNameEmpty)
    }

    // MARK: - Granularity

    func testDefaultGranularityIsThree() {
        let vm = BreakdownSheetViewModel()
        XCTAssertEqual(vm.granularity, 3)
    }

    func testGranularityRangeIsOneToFive() {
        let vm = BreakdownSheetViewModel()
        for value in 1...5 {
            vm.granularity = value
            XCTAssertEqual(vm.granularity, value)
        }
    }
}
