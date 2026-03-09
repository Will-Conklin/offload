// Purpose: Unit tests for BrainDumpSheetViewModel.
// Authority: Code-level
// Governed by: CLAUDE.md

@testable import Offload
import XCTest

// MARK: - Stubs

private final class StubBrainDumpService: BrainDumpService {
    var stubbedResult: Result<BrainDumpExecutionResult, Error> = .success(
        BrainDumpExecutionResult(
            items: [
                BrainDumpItem(title: "Item A", type: "task"),
                BrainDumpItem(title: "Item B", type: "idea"),
            ],
            source: .onDevice,
            usage: nil
        )
    )
    var compileCallCount = 0

    func compileBrainDump(
        inputText: String,
        contextHints: [String]
    ) async throws -> BrainDumpExecutionResult {
        compileCallCount += 1
        switch stubbedResult {
        case .success(let result): return result
        case .failure(let error): throw error
        }
    }

    func reconcileUsage(feature: String) async throws -> UsageReconcileResponse? { nil }
}

// MARK: - Tests

@MainActor
final class BrainDumpSheetViewModelTests: XCTestCase {

    // MARK: - Phase management

    func testInitialPhaseIsConfigure() {
        let vm = BrainDumpSheetViewModel()
        XCTAssertEqual(vm.phase, .configure)
    }

    func testCompileSetsPhaseToPreview() async throws {
        let vm = BrainDumpSheetViewModel()
        let service = StubBrainDumpService()

        try await vm.compile(inputText: "A long capture with many thoughts and ideas", using: service)

        XCTAssertEqual(vm.phase, .preview)
    }

    // MARK: - Item population

    func testCompilePopulatesItemsFromService() async throws {
        let vm = BrainDumpSheetViewModel()
        let service = StubBrainDumpService()
        service.stubbedResult = .success(BrainDumpExecutionResult(
            items: [
                BrainDumpItem(title: "First", type: "task"),
                BrainDumpItem(title: "Second", type: "note"),
                BrainDumpItem(title: "Third", type: "idea"),
            ],
            source: .onDevice,
            usage: nil
        ))

        try await vm.compile(inputText: "Long dump", using: service)

        XCTAssertEqual(vm.extractedItems.count, 3)
        XCTAssertEqual(vm.extractedItems[0].title, "First")
        XCTAssertEqual(vm.extractedItems[0].itemType, .task)
        XCTAssertEqual(vm.extractedItems[1].title, "Second")
        XCTAssertEqual(vm.extractedItems[1].itemType, .note)
    }

    func testUnknownTypeMapsToNote() async throws {
        let vm = BrainDumpSheetViewModel()
        let service = StubBrainDumpService()
        service.stubbedResult = .success(BrainDumpExecutionResult(
            items: [BrainDumpItem(title: "Item", type: "unknown_type")],
            source: .onDevice,
            usage: nil
        ))

        try await vm.compile(inputText: "Any text", using: service)

        XCTAssertEqual(vm.extractedItems.first?.itemType, .note)
    }

    // MARK: - List name derivation

    func testCompileDerivesDefaultListNameFromInputText() async throws {
        let vm = BrainDumpSheetViewModel()
        let service = StubBrainDumpService()

        try await vm.compile(inputText: "Organize the home office and other tasks", using: service)

        XCTAssertFalse(vm.listName.isEmpty)
        XCTAssertTrue(vm.listName.contains("Organize"))
    }

    func testCompilePreservesExistingListNameIfSet() async throws {
        let vm = BrainDumpSheetViewModel()
        vm.listName = "My custom list"
        let service = StubBrainDumpService()

        try await vm.compile(inputText: "Something else", using: service)

        XCTAssertEqual(vm.listName, "My custom list")
    }

    // MARK: - Loading state

    func testIsCompilingFalseAfterCompletion() async throws {
        let vm = BrainDumpSheetViewModel()
        let service = StubBrainDumpService()

        XCTAssertFalse(vm.isCompiling)
        try await vm.compile(inputText: "Some text", using: service)
        XCTAssertFalse(vm.isCompiling)
    }

    // MARK: - Error propagation

    func testCompilePropagatesServiceErrors() async {
        let vm = BrainDumpSheetViewModel()
        let service = StubBrainDumpService()
        service.stubbedResult = .failure(AIBackendClientError.transport)

        do {
            try await vm.compile(inputText: "Some text", using: service)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(vm.phase, .configure, "Phase should remain .configure on failure")
        }
    }

    // MARK: - Item editing

    func testItemsAreEditable() async throws {
        let vm = BrainDumpSheetViewModel()
        let service = StubBrainDumpService()

        try await vm.compile(inputText: "Some text", using: service)

        vm.extractedItems[0].title = "Edited title"
        XCTAssertEqual(vm.extractedItems[0].title, "Edited title")
    }

    func testRemoveItemDeletesFromList() async throws {
        let vm = BrainDumpSheetViewModel()
        let service = StubBrainDumpService()

        try await vm.compile(inputText: "Some text", using: service)
        XCTAssertEqual(vm.extractedItems.count, 2)

        let first = vm.extractedItems[0]
        vm.removeItem(first)

        XCTAssertEqual(vm.extractedItems.count, 1)
        XCTAssertFalse(vm.extractedItems.contains { $0.id == first.id })
    }

    // MARK: - isListNameEmpty

    func testIsListNameEmptyTrueWhenBlank() {
        let vm = BrainDumpSheetViewModel()
        XCTAssertTrue(vm.isListNameEmpty)
    }

    func testIsListNameEmptyFalseWhenSet() {
        let vm = BrainDumpSheetViewModel()
        vm.listName = "My List"
        XCTAssertFalse(vm.isListNameEmpty)
    }

    // MARK: - hasNoItems

    func testHasNoItemsTrueWhenEmpty() {
        let vm = BrainDumpSheetViewModel()
        XCTAssertTrue(vm.hasNoItems)
    }

    func testHasNoItemsFalseAfterCompile() async throws {
        let vm = BrainDumpSheetViewModel()
        let service = StubBrainDumpService()

        try await vm.compile(inputText: "Some text", using: service)

        XCTAssertFalse(vm.hasNoItems)
    }
}
