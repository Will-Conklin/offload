//
//  PlanRepositoryTests.swift
//  OffloadTests
//
//  Created by Claude Code on 12/31/25.
//

import XCTest
import SwiftData
@testable import offload

@MainActor
final class PlanRepositoryTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var repository: PlanRepository!

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
        repository = PlanRepository(modelContext: modelContext)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        repository = nil
    }

    func testCreatePlan() throws {
        let plan = Plan(title: "Work Projects")

        try repository.create(plan: plan)

        let fetched = try repository.fetchAll()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "Work Projects")
    }

    func testArchivePlan() throws {
        let plan = Plan(title: "Old Plan")

        try repository.create(plan: plan)
        XCTAssertFalse(plan.isArchived)

        try repository.archive(plan: plan)
        XCTAssertTrue(plan.isArchived)

        let archived = try repository.fetchArchived()
        XCTAssertEqual(archived.count, 1)

        let active = try repository.fetchActive()
        XCTAssertEqual(active.count, 0)
    }
}
