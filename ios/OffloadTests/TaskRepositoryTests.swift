//
//  TaskRepositoryTests.swift
//  OffloadTests
//
//  Created by Claude Code on 12/31/25.
//

import XCTest
import SwiftData
@testable import offload

@MainActor
final class TaskRepositoryTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var repository: TaskRepository!

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
        repository = TaskRepository(modelContext: modelContext)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        repository = nil
    }

    func testCreateTask() throws {
        let task = Task(title: "Buy groceries")

        try repository.create(task: task)

        let fetched = try repository.fetchAll()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "Buy groceries")
    }

    func testCompleteTask() throws {
        let task = Task(title: "Complete this task")

        try repository.create(task: task)
        XCTAssertFalse(task.isDone)

        try repository.complete(task: task)
        XCTAssertTrue(task.isDone)

        let completed = try repository.fetchCompleted()
        XCTAssertEqual(completed.count, 1)
    }

    func testTaskPlanRelationship() throws {
        let plan = Plan(title: "Home")
        modelContext.insert(plan)

        let task = Task(title: "Fix the sink", plan: plan)
        try repository.create(task: task)

        let tasksInPlan = try repository.fetchByPlan(plan)
        XCTAssertEqual(tasksInPlan.count, 1)
        XCTAssertEqual(tasksInPlan.first?.title, "Fix the sink")
    }
}
