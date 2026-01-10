//
//  HandOffRepositoryTests.swift
//  OffloadTests
//
//  Created by Claude Code on 12/31/25.
//

import XCTest
import SwiftData
@testable import offload

@MainActor
final class HandOffRepositoryTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var repository: HandOffRepository!
    var brainDumpRepo: CaptureRepository!

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
        repository = HandOffRepository(modelContext: modelContext)
        brainDumpRepo = CaptureRepository(modelContext: modelContext)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        repository = nil
        brainDumpRepo = nil
    }

    func testCreateRequest() throws {
        let entry = CaptureEntry(rawText: "Test entry", inputType: .text, source: .app)
        try brainDumpRepo.create(entry: entry)

        let request = HandOffRequest(
            requestedBy: .user,
            mode: .manual,
            captureEntry: entry
        )

        try repository.createRequest(request: request)

        let fetched = try repository.fetchAllRequests()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.source, .user)
        XCTAssertEqual(fetched.first?.handOffMode, .manual)
    }

    func testFetchRequestsByEntry() throws {
        let entry1 = CaptureEntry(rawText: "Entry 1", inputType: .text, source: .app)
        let entry2 = CaptureEntry(rawText: "Entry 2", inputType: .text, source: .app)
        try brainDumpRepo.create(entry: entry1)
        try brainDumpRepo.create(entry: entry2)

        let request1 = HandOffRequest(requestedBy: .user, mode: .manual, captureEntry: entry1)
        let request2 = HandOffRequest(requestedBy: .auto, mode: .auto, captureEntry: entry1)
        let request3 = HandOffRequest(requestedBy: .user, mode: .manual, captureEntry: entry2)

        try repository.createRequest(request: request1)
        try repository.createRequest(request: request2)
        try repository.createRequest(request: request3)

        let entry1Requests = try repository.fetchRequestsByEntry(entry1.id)
        XCTAssertEqual(entry1Requests.count, 2)
    }

    func testFetchRequestsBySource() throws {
        let request1 = HandOffRequest(requestedBy: .user, mode: .manual)
        let request2 = HandOffRequest(requestedBy: .auto, mode: .auto)
        let request3 = HandOffRequest(requestedBy: .user, mode: .manual)

        try repository.createRequest(request: request1)
        try repository.createRequest(request: request2)
        try repository.createRequest(request: request3)

        let userRequests = try repository.fetchRequestsBySource(.user)
        XCTAssertEqual(userRequests.count, 2)

        let autoRequests = try repository.fetchRequestsBySource(.auto)
        XCTAssertEqual(autoRequests.count, 1)
    }

    func testCreateRun() throws {
        let request = HandOffRequest(requestedBy: .user, mode: .manual)
        try repository.createRequest(request: request)

        let run = HandOffRun(
            modelId: "claude-3-5-sonnet",
            promptVersion: "v1",
            inputSnapshot: "Test input",
            handOffRequest: request
        )

        try repository.createRun(run: run)

        let fetched = try repository.fetchRunsByRequest(request.id)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.modelId, "claude-3-5-sonnet")
        XCTAssertEqual(fetched.first?.status, .running)
    }

    func testUpdateRunStatus() throws {
        let run = HandOffRun(
            modelId: "claude-3-5-sonnet",
            promptVersion: "v1",
            inputSnapshot: "Test"
        )

        try repository.createRun(run: run)
        XCTAssertEqual(run.status, .running)
        XCTAssertNil(run.completedAt)

        try repository.updateRunStatus(run: run, status: .completed)
        XCTAssertEqual(run.status, .completed)
        XCTAssertNotNil(run.completedAt)
    }

    func testUpdateRunStatusWithError() throws {
        let run = HandOffRun(
            modelId: "claude-3-5-sonnet",
            promptVersion: "v1",
            inputSnapshot: "Test"
        )

        try repository.createRun(run: run)

        try repository.updateRunStatus(run: run, status: .failed, errorMessage: "API timeout")
        XCTAssertEqual(run.status, .failed)
        XCTAssertEqual(run.errorMessage, "API timeout")
        XCTAssertNotNil(run.completedAt)
    }

    func testFetchRunsByStatus() throws {
        let run1 = HandOffRun(modelId: "model1", promptVersion: "v1", inputSnapshot: "Test1")
        let run2 = HandOffRun(modelId: "model2", promptVersion: "v1", inputSnapshot: "Test2")
        let run3 = HandOffRun(modelId: "model3", promptVersion: "v1", inputSnapshot: "Test3")

        try repository.createRun(run: run1)
        try repository.createRun(run: run2)
        try repository.createRun(run: run3)

        try repository.updateRunStatus(run: run2, status: .completed)
        try repository.updateRunStatus(run: run3, status: .failed)

        let running = try repository.fetchRunsByStatus(.running)
        XCTAssertEqual(running.count, 1)

        let completed = try repository.fetchRunsByStatus(.completed)
        XCTAssertEqual(completed.count, 1)

        let failed = try repository.fetchRunsByStatus(.failed)
        XCTAssertEqual(failed.count, 1)
    }

    func testDeleteRequestCascadesToRuns() throws {
        let request = HandOffRequest(requestedBy: .user, mode: .manual)
        try repository.createRequest(request: request)

        let run = HandOffRun(
            modelId: "claude-3-5-sonnet",
            promptVersion: "v1",
            inputSnapshot: "Test",
            handOffRequest: request
        )
        try repository.createRun(run: run)

        try repository.deleteRequest(request: request)

        let requests = try repository.fetchAllRequests()
        XCTAssertEqual(requests.count, 0)

        // Run should be deleted due to cascade
        let runs = try repository.fetchRunsByRequest(request.id)
        XCTAssertEqual(runs.count, 0)
    }
}
