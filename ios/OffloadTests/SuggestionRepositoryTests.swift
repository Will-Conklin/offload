//
//  SuggestionRepositoryTests.swift
//  OffloadTests
//
//  Created by Claude Code on 12/31/25.
//

import XCTest
import SwiftData
@testable import offload

@MainActor
final class SuggestionRepositoryTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var repository: SuggestionRepository!

    override func setUp() async throws {
        let schema = Schema([
            CaptureEntry.self,
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
        repository = SuggestionRepository(modelContext: modelContext)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        repository = nil
    }

    func testCreateSuggestion() throws {
        let suggestion = Suggestion(
            kind: .task,
            payloadJSON: "{\"title\":\"Buy groceries\"}",
            confidence: 0.95
        )

        try repository.createSuggestion(suggestion: suggestion)

        let fetched = try repository.fetchAllSuggestions()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.suggestionKind, .task)
        XCTAssertEqual(fetched.first?.confidence, 0.95)
    }

    func testFetchSuggestionsByRun() throws {
        let run1 = HandOffRun(modelId: "claude", promptVersion: "v1", inputSnapshot: "Test1")
        let run2 = HandOffRun(modelId: "claude", promptVersion: "v1", inputSnapshot: "Test2")
        modelContext.insert(run1)
        modelContext.insert(run2)

        let suggestion1 = Suggestion(kind: .task, payloadJSON: "{}", handOffRun: run1)
        let suggestion2 = Suggestion(kind: .plan, payloadJSON: "{}", handOffRun: run1)
        let suggestion3 = Suggestion(kind: .list, payloadJSON: "{}", handOffRun: run2)

        try repository.createSuggestion(suggestion: suggestion1)
        try repository.createSuggestion(suggestion: suggestion2)
        try repository.createSuggestion(suggestion: suggestion3)

        let run1Suggestions = try repository.fetchSuggestionsByRun(run1.id)
        XCTAssertEqual(run1Suggestions.count, 2)
    }

    func testFetchSuggestionsByKind() throws {
        let suggestion1 = Suggestion(kind: .task, payloadJSON: "{}")
        let suggestion2 = Suggestion(kind: .plan, payloadJSON: "{}")
        let suggestion3 = Suggestion(kind: .task, payloadJSON: "{}")

        try repository.createSuggestion(suggestion: suggestion1)
        try repository.createSuggestion(suggestion: suggestion2)
        try repository.createSuggestion(suggestion: suggestion3)

        let tasks = try repository.fetchSuggestionsByKind(.task)
        XCTAssertEqual(tasks.count, 2)

        let plans = try repository.fetchSuggestionsByKind(.plan)
        XCTAssertEqual(plans.count, 1)
    }

    func testRecordDecision() throws {
        let suggestion = Suggestion(kind: .task, payloadJSON: "{}")
        try repository.createSuggestion(suggestion: suggestion)

        let decision = SuggestionDecision(
            decision: .accepted,
            decidedBy: .user,
            suggestion: suggestion
        )

        try repository.recordDecision(decision: decision)

        let decisions = try repository.fetchDecisionsBySuggestion(suggestion.id)
        XCTAssertEqual(decisions.count, 1)
        XCTAssertEqual(decisions.first?.decisionType, .accepted)
        XCTAssertEqual(decisions.first?.source, .user)
    }

    func testFetchDecisionsByType() throws {
        let suggestion1 = Suggestion(kind: .task, payloadJSON: "{}")
        let suggestion2 = Suggestion(kind: .plan, payloadJSON: "{}")
        try repository.createSuggestion(suggestion: suggestion1)
        try repository.createSuggestion(suggestion: suggestion2)

        let decision1 = SuggestionDecision(decision: .accepted, decidedBy: .user, suggestion: suggestion1)
        let decision2 = SuggestionDecision(decision: .rejected, decidedBy: .user, suggestion: suggestion2)

        try repository.recordDecision(decision: decision1)
        try repository.recordDecision(decision: decision2)

        let accepted = try repository.fetchDecisionsByType(.accepted)
        XCTAssertEqual(accepted.count, 1)

        let rejected = try repository.fetchDecisionsByType(.rejected)
        XCTAssertEqual(rejected.count, 1)
    }

    func testFetchPendingSuggestionsForEntry() throws {
        let entry = CaptureEntry(rawText: "Test entry", inputType: .text, source: .app)
        let request = HandOffRequest(requestedBy: .user, mode: .manual, captureEntry: entry)
        let run = HandOffRun(modelId: "claude", promptVersion: "v1", inputSnapshot: "Test", handOffRequest: request)

        modelContext.insert(entry)
        modelContext.insert(request)
        modelContext.insert(run)

        let suggestion1 = Suggestion(kind: .task, payloadJSON: "{}", handOffRun: run)
        let suggestion2 = Suggestion(kind: .plan, payloadJSON: "{}", handOffRun: run)
        let suggestion3 = Suggestion(kind: .list, payloadJSON: "{}", handOffRun: run)

        try repository.createSuggestion(suggestion: suggestion1)
        try repository.createSuggestion(suggestion: suggestion2)
        try repository.createSuggestion(suggestion: suggestion3)

        // Accept one suggestion
        let decision = SuggestionDecision(decision: .accepted, decidedBy: .user, suggestion: suggestion1)
        try repository.recordDecision(decision: decision)

        let pending = try repository.fetchPendingSuggestionsForEntry(entry.id)
        XCTAssertEqual(pending.count, 2)  // suggestion2 and suggestion3 are pending
    }

    func testDeleteSuggestionCascadesToDecisions() throws {
        let suggestion = Suggestion(kind: .task, payloadJSON: "{}")
        try repository.createSuggestion(suggestion: suggestion)

        let decision = SuggestionDecision(decision: .accepted, decidedBy: .user, suggestion: suggestion)
        try repository.recordDecision(decision: decision)

        try repository.deleteSuggestion(suggestion: suggestion)

        let suggestions = try repository.fetchAllSuggestions()
        XCTAssertEqual(suggestions.count, 0)

        // Decision should be deleted due to cascade
        let decisions = try repository.fetchDecisionsBySuggestion(suggestion.id)
        XCTAssertEqual(decisions.count, 0)
    }
}
