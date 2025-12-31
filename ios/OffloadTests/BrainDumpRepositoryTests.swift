//
//  BrainDumpRepositoryTests.swift
//  OffloadTests
//
//  Created by Claude Code on 12/31/25.
//

import XCTest
import SwiftData
@testable import offload

@MainActor
final class BrainDumpRepositoryTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var repository: BrainDumpRepository!

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
        repository = BrainDumpRepository(modelContext: modelContext)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        repository = nil
    }

    func testCreateEntry() throws {
        let entry = BrainDumpEntry(
            rawText: "Test entry",
            inputType: .text,
            source: .app
        )

        try repository.create(entry: entry)

        let fetched = try repository.fetchAll()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.rawText, "Test entry")
    }

    func testLifecycleStateTransitions() throws {
        let entry = BrainDumpEntry(
            rawText: "Test lifecycle",
            inputType: .text,
            source: .app,
            lifecycleState: .raw
        )

        try repository.create(entry: entry)
        XCTAssertEqual(entry.currentLifecycleState, .raw)

        try repository.updateLifecycleState(entry: entry, to: .handedOff)
        XCTAssertEqual(entry.currentLifecycleState, .handedOff)

        try repository.updateLifecycleState(entry: entry, to: .ready)
        XCTAssertEqual(entry.currentLifecycleState, .ready)
    }

    func testFetchInbox() throws {
        let entry1 = BrainDumpEntry(rawText: "Inbox entry", inputType: .text, source: .app, lifecycleState: .raw)
        let entry2 = BrainDumpEntry(rawText: "Placed entry", inputType: .text, source: .app, lifecycleState: .placed)

        try repository.create(entry: entry1)
        try repository.create(entry: entry2)

        let inboxEntries = try repository.fetchInbox()
        XCTAssertEqual(inboxEntries.count, 1)
        XCTAssertEqual(inboxEntries.first?.rawText, "Inbox entry")
    }
}
