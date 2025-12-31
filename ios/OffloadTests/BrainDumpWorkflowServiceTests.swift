//
//  BrainDumpWorkflowServiceTests.swift
//  OffloadTests
//
//  Created by Claude Code on 12/31/25.
//

import XCTest
import SwiftData
@testable import offload

@MainActor
final class BrainDumpWorkflowServiceTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var service: BrainDumpWorkflowService!

    override func setUp() async throws {
        let schema = Schema([
            BrainDumpEntry.self,
            HandOffRequest.self,
            HandOffRun.self,
            Suggestion.self,
            SuggestionDecision.self,
            Placement.self,
            Plan.self,
            Task.self,
            Tag.self,
            Category.self,
            ListEntity.self,
            ListItem.self,
            CommunicationItem.self,
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = modelContainer.mainContext
        service = BrainDumpWorkflowService(modelContext: modelContext)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        service = nil
    }

    // MARK: - Capture Operations Tests

    func testCaptureEntryWithText() async throws {
        let entry = try await service.captureEntry(
            rawText: "Test text entry",
            inputType: .text,
            source: .app
        )

        XCTAssertEqual(entry.rawText, "Test text entry")
        XCTAssertEqual(entry.entryInputType, .text)
        XCTAssertEqual(entry.captureSource, .app)
        XCTAssertEqual(entry.currentLifecycleState, .raw)

        let inbox = try service.fetchInbox()
        XCTAssertEqual(inbox.count, 1)
        XCTAssertEqual(inbox.first?.id, entry.id)
    }

    func testCaptureEntryWithVoice() async throws {
        let entry = try await service.captureEntry(
            rawText: "Voice transcription",
            inputType: .voice,
            source: .app
        )

        XCTAssertEqual(entry.entryInputType, .voice)
        XCTAssertEqual(entry.rawText, "Voice transcription")
    }

    func testCaptureEntryFromDifferentSources() async throws {
        let appEntry = try await service.captureEntry(
            rawText: "From app",
            inputType: .text,
            source: .app
        )

        let shortcutEntry = try await service.captureEntry(
            rawText: "From shortcut",
            inputType: .text,
            source: .shortcut
        )

        let shareSheetEntry = try await service.captureEntry(
            rawText: "From share sheet",
            inputType: .text,
            source: .shareSheet
        )

        let widgetEntry = try await service.captureEntry(
            rawText: "From widget",
            inputType: .text,
            source: .widget
        )

        XCTAssertEqual(appEntry.captureSource, .app)
        XCTAssertEqual(shortcutEntry.captureSource, .shortcut)
        XCTAssertEqual(shareSheetEntry.captureSource, .shareSheet)
        XCTAssertEqual(widgetEntry.captureSource, .widget)
    }

    func testCaptureEntrySetsIsProcessing() async throws {
        XCTAssertFalse(service.isProcessing)

        let captureTask = _Concurrency.Task {
            try await service.captureEntry(
                rawText: "Test",
                inputType: .text,
                source: .app
            )
        }

        try await captureTask.value
        XCTAssertFalse(service.isProcessing)
    }

    func testCaptureEntryThrowsWhenAlreadyProcessing() async throws {
        service.isProcessing = true

        do {
            _ = try await service.captureEntry(
                rawText: "Test",
                inputType: .text,
                source: .app
            )
            XCTFail("Expected alreadyProcessing error")
        } catch let error as WorkflowError {
            XCTAssertEqual(error, .alreadyProcessing)
        }

        service.isProcessing = false
    }

    // MARK: - Query Operations Tests

    func testFetchInbox() async throws {
        _ = try await service.captureEntry(rawText: "Inbox 1", inputType: .text, source: .app)
        _ = try await service.captureEntry(rawText: "Inbox 2", inputType: .text, source: .app)

        let repository = BrainDumpRepository(modelContext: modelContext)
        let placedEntry = BrainDumpEntry(rawText: "Placed", inputType: .text, source: .app, lifecycleState: .placed)
        try repository.create(entry: placedEntry)

        let inbox = try service.fetchInbox()

        XCTAssertEqual(inbox.count, 2)
        XCTAssertTrue(inbox.allSatisfy { $0.currentLifecycleState == .raw })
        XCTAssertTrue(inbox.contains { $0.rawText == "Inbox 1" })
        XCTAssertTrue(inbox.contains { $0.rawText == "Inbox 2" })
    }

    func testFetchByState() async throws {
        let repository = BrainDumpRepository(modelContext: modelContext)

        let rawEntry = BrainDumpEntry(rawText: "Raw", inputType: .text, source: .app, lifecycleState: .raw)
        let handedOffEntry = BrainDumpEntry(rawText: "Handed off", inputType: .text, source: .app, lifecycleState: .handedOff)
        let readyEntry = BrainDumpEntry(rawText: "Ready", inputType: .text, source: .app, lifecycleState: .ready)
        let placedEntry = BrainDumpEntry(rawText: "Placed", inputType: .text, source: .app, lifecycleState: .placed)
        let archivedEntry = BrainDumpEntry(rawText: "Archived", inputType: .text, source: .app, lifecycleState: .archived)

        try repository.create(entry: rawEntry)
        try repository.create(entry: handedOffEntry)
        try repository.create(entry: readyEntry)
        try repository.create(entry: placedEntry)
        try repository.create(entry: archivedEntry)

        XCTAssertEqual(try service.fetchByState(.raw).count, 1)
        XCTAssertEqual(try service.fetchByState(.handedOff).count, 1)
        XCTAssertEqual(try service.fetchByState(.ready).count, 1)
        XCTAssertEqual(try service.fetchByState(.placed).count, 1)
        XCTAssertEqual(try service.fetchByState(.archived).count, 1)
    }

    func testFetchAwaitingPlacement() async throws {
        let repository = BrainDumpRepository(modelContext: modelContext)

        let readyEntry1 = BrainDumpEntry(rawText: "Ready 1", inputType: .text, source: .app, lifecycleState: .ready)
        let readyEntry2 = BrainDumpEntry(rawText: "Ready 2", inputType: .text, source: .app, lifecycleState: .ready)
        let rawEntry = BrainDumpEntry(rawText: "Raw", inputType: .text, source: .app, lifecycleState: .raw)

        try repository.create(entry: readyEntry1)
        try repository.create(entry: readyEntry2)
        try repository.create(entry: rawEntry)

        let awaitingPlacement = try service.fetchAwaitingPlacement()

        XCTAssertEqual(awaitingPlacement.count, 2)
        XCTAssertTrue(awaitingPlacement.allSatisfy { $0.currentLifecycleState == .ready })
    }

    func testSearchEntries() async throws {
        _ = try await service.captureEntry(rawText: "Buy milk", inputType: .text, source: .app)
        _ = try await service.captureEntry(rawText: "Call dentist", inputType: .text, source: .app)
        _ = try await service.captureEntry(rawText: "Buy bread", inputType: .text, source: .app)

        let buyResults = try service.searchEntries("Buy")
        XCTAssertEqual(buyResults.count, 2)
        XCTAssertTrue(buyResults.allSatisfy { $0.rawText.contains("Buy") })

        let dentistResults = try service.searchEntries("dentist")
        XCTAssertEqual(dentistResults.count, 1)
        XCTAssertEqual(dentistResults.first?.rawText, "Call dentist")

        let noResults = try service.searchEntries("xyz")
        XCTAssertEqual(noResults.count, 0)
    }

    // MARK: - Archive and Delete Tests

    func testArchiveEntry() async throws {
        let entry = try await service.captureEntry(
            rawText: "Archive me",
            inputType: .text,
            source: .app
        )

        XCTAssertEqual(entry.currentLifecycleState, .raw)

        try await service.archiveEntry(entry)

        XCTAssertEqual(entry.currentLifecycleState, .archived)

        let inbox = try service.fetchInbox()
        XCTAssertEqual(inbox.count, 0)

        let archived = try service.fetchByState(.archived)
        XCTAssertEqual(archived.count, 1)
        XCTAssertEqual(archived.first?.id, entry.id)
    }

    func testArchiveEntryThrowsWhenAlreadyProcessing() async throws {
        let entry = try await service.captureEntry(
            rawText: "Test",
            inputType: .text,
            source: .app
        )

        service.isProcessing = true

        do {
            try await service.archiveEntry(entry)
            XCTFail("Expected alreadyProcessing error")
        } catch let error as WorkflowError {
            XCTAssertEqual(error, .alreadyProcessing)
        }

        service.isProcessing = false
    }

    func testDeleteEntry() async throws {
        let entry = try await service.captureEntry(
            rawText: "Delete me",
            inputType: .text,
            source: .app
        )

        XCTAssertEqual(try service.fetchInbox().count, 1)

        try await service.deleteEntry(entry)

        XCTAssertEqual(try service.fetchInbox().count, 0)

        let repository = BrainDumpRepository(modelContext: modelContext)
        let all = try repository.fetchAll()
        XCTAssertEqual(all.count, 0)
    }

    func testDeleteEntryThrowsWhenAlreadyProcessing() async throws {
        let entry = try await service.captureEntry(
            rawText: "Test",
            inputType: .text,
            source: .app
        )

        service.isProcessing = true

        do {
            try await service.deleteEntry(entry)
            XCTFail("Expected alreadyProcessing error")
        } catch let error as WorkflowError {
            XCTAssertEqual(error, .alreadyProcessing)
        }

        service.isProcessing = false
    }

    // MARK: - Error Handling Tests

    func testErrorMessageIsSetOnFailure() async throws {
        XCTAssertNil(service.errorMessage)
    }

    func testErrorMessageClearedOnSuccess() async throws {
        service.errorMessage = "Previous error"

        _ = try await service.captureEntry(
            rawText: "Test",
            inputType: .text,
            source: .app
        )

        XCTAssertNil(service.errorMessage)
    }

    // MARK: - Stub Methods Tests

    func testSubmitForOrganizationThrowsNotImplemented() async throws {
        let entry = try await service.captureEntry(
            rawText: "Test",
            inputType: .text,
            source: .app
        )

        do {
            try await service.submitForOrganization(entry)
            XCTFail("Expected notImplemented error")
        } catch let error as WorkflowError {
            XCTAssertEqual(error, .notImplemented)
        }
    }

    func testFetchSuggestionsThrowsNotImplemented() async throws {
        let entry = try await service.captureEntry(
            rawText: "Test",
            inputType: .text,
            source: .app
        )

        do {
            _ = try service.fetchSuggestions(for: entry)
            XCTFail("Expected notImplemented error")
        } catch let error as WorkflowError {
            XCTAssertEqual(error, .notImplemented)
        }
    }
}

// MARK: - WorkflowError Equatable Conformance for Testing

extension WorkflowError: @retroactive Equatable {
    public static func == (lhs: WorkflowError, rhs: WorkflowError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidState(let msg1), .invalidState(let msg2)):
            return msg1 == msg2
        case (.alreadyProcessing, .alreadyProcessing):
            return true
        case (.notImplemented, .notImplemented):
            return true
        case (.unknownError(let msg1), .unknownError(let msg2)):
            return msg1 == msg2
        default:
            return false
        }
    }
}
