//
//  PlacementRepositoryTests.swift
//  OffloadTests
//
//  Created by Claude Code on 12/31/25.
//

import XCTest
import SwiftData
@testable import offload

@MainActor
final class PlacementRepositoryTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var repository: PlacementRepository!

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
        repository = PlacementRepository(modelContext: modelContext)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        repository = nil
    }

    func testCreatePlacement() throws {
        let suggestionId = UUID()
        let targetId = UUID()

        let placement = Placement(
            targetType: .task,
            targetId: targetId,
            sourceSuggestionId: suggestionId,
            notes: "Placed successfully"
        )

        try repository.create(placement: placement)

        let fetched = try repository.fetchAll()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.target, .task)
        XCTAssertEqual(fetched.first?.targetId, targetId)
        XCTAssertEqual(fetched.first?.sourceSuggestionId, suggestionId)
    }

    func testFetchBySourceSuggestion() throws {
        let suggestionId1 = UUID()
        let suggestionId2 = UUID()

        let placement1 = Placement(targetType: .task, targetId: UUID(), sourceSuggestionId: suggestionId1)
        let placement2 = Placement(targetType: .plan, targetId: UUID(), sourceSuggestionId: suggestionId1)
        let placement3 = Placement(targetType: .list, targetId: UUID(), sourceSuggestionId: suggestionId2)

        try repository.create(placement: placement1)
        try repository.create(placement: placement2)
        try repository.create(placement: placement3)

        let placements = try repository.fetchBySourceSuggestion(suggestionId1)
        XCTAssertEqual(placements.count, 2)
    }

    func testFetchByTargetType() throws {
        let placement1 = Placement(targetType: .task, targetId: UUID(), sourceSuggestionId: UUID())
        let placement2 = Placement(targetType: .plan, targetId: UUID(), sourceSuggestionId: UUID())
        let placement3 = Placement(targetType: .task, targetId: UUID(), sourceSuggestionId: UUID())

        try repository.create(placement: placement1)
        try repository.create(placement: placement2)
        try repository.create(placement: placement3)

        let tasks = try repository.fetchByTargetType(.task)
        XCTAssertEqual(tasks.count, 2)

        let plans = try repository.fetchByTargetType(.plan)
        XCTAssertEqual(plans.count, 1)
    }

    func testFetchByTarget() throws {
        let targetId = UUID()

        let placement1 = Placement(targetType: .task, targetId: targetId, sourceSuggestionId: UUID())
        let placement2 = Placement(targetType: .task, targetId: UUID(), sourceSuggestionId: UUID())
        let placement3 = Placement(targetType: .plan, targetId: targetId, sourceSuggestionId: UUID())

        try repository.create(placement: placement1)
        try repository.create(placement: placement2)
        try repository.create(placement: placement3)

        let taskPlacements = try repository.fetchByTarget(type: .task, id: targetId)
        XCTAssertEqual(taskPlacements.count, 1)
        XCTAssertEqual(taskPlacements.first?.targetId, targetId)
    }

    func testUpdatePlacement() throws {
        let placement = Placement(
            targetType: .task,
            targetId: UUID(),
            sourceSuggestionId: UUID()
        )

        try repository.create(placement: placement)
        XCTAssertNil(placement.notes)

        placement.notes = "Updated notes"
        try repository.update(placement: placement)

        let fetched = try repository.fetchById(placement.id)
        XCTAssertEqual(fetched?.notes, "Updated notes")
    }

    func testDeletePlacement() throws {
        let placement = Placement(
            targetType: .task,
            targetId: UUID(),
            sourceSuggestionId: UUID()
        )

        try repository.create(placement: placement)
        XCTAssertEqual(try repository.fetchAll().count, 1)

        try repository.delete(placement: placement)
        XCTAssertEqual(try repository.fetchAll().count, 0)
    }
}
