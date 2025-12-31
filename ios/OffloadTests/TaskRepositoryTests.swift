//
//  TaskRepositoryTests.swift
//  OffloadTests
//
//  Created by Claude Code on 12/31/24.
//

import XCTest
import SwiftData
@testable import offload

@MainActor
final class TaskRepositoryTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var repository: TaskRepository!

    override func setUpWithError() throws {
        // Create in-memory model container for testing
        let schema = Schema([
            Task.self,
            Project.self,
            Tag.self,
            Category.self,
            Thought.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = modelContainer.mainContext
        repository = TaskRepository(modelContext: modelContext)
    }

    override func tearDownWithError() throws {
        repository = nil
        modelContext = nil
        modelContainer = nil
    }

    // MARK: - Create Tests

    func testCreateTask() throws {
        // Given
        let task = Task(title: "Test Task")

        // When
        try repository.create(task: task)

        // Then
        let allTasks = try repository.fetchAll()
        XCTAssertEqual(allTasks.count, 1)
        XCTAssertEqual(allTasks.first?.title, "Test Task")
    }

    // MARK: - Fetch Tests

    func testFetchAll() throws {
        // Given
        try repository.create(task: Task(title: "Task 1"))
        try repository.create(task: Task(title: "Task 2"))
        try repository.create(task: Task(title: "Task 3"))

        // When
        let tasks = try repository.fetchAll()

        // Then
        XCTAssertEqual(tasks.count, 3)
    }

    func testFetchInbox() throws {
        // Given
        try repository.create(task: Task(title: "Inbox Task", status: .inbox))
        try repository.create(task: Task(title: "Next Task", status: .next))
        try repository.create(task: Task(title: "Completed Task", status: .completed))

        // When
        let inboxTasks = try repository.fetchInbox()

        // Then
        XCTAssertEqual(inboxTasks.count, 1)
        XCTAssertEqual(inboxTasks.first?.title, "Inbox Task")
        XCTAssertEqual(inboxTasks.first?.status, .inbox)
    }

    func testFetchNext() throws {
        // Given
        let oldDate = Date(timeIntervalSinceNow: -3600)
        let recentDate = Date()

        try repository.create(task: Task(
            title: "Next Task 1",
            createdAt: oldDate,
            status: .next
        ))
        try repository.create(task: Task(
            title: "Next Task 2",
            createdAt: recentDate,
            status: .next
        ))
        try repository.create(task: Task(title: "Inbox Task", status: .inbox))

        // When
        let nextTasks = try repository.fetchNext()

        // Then
        XCTAssertEqual(nextTasks.count, 2)
        // Should be sorted by createdAt ascending
        XCTAssertEqual(nextTasks.first?.title, "Next Task 1")
        XCTAssertEqual(nextTasks.last?.title, "Next Task 2")
    }

    func testFetchByStatus() throws {
        // Given
        try repository.create(task: Task(title: "Task 1", status: .waiting))
        try repository.create(task: Task(title: "Task 2", status: .waiting))
        try repository.create(task: Task(title: "Task 3", status: .someday))

        // When
        let waitingTasks = try repository.fetchByStatus(.waiting)

        // Then
        XCTAssertEqual(waitingTasks.count, 2)
        XCTAssertTrue(waitingTasks.allSatisfy { $0.status == .waiting })
    }

    func testFetchByProject() throws {
        // Given
        let project1 = Project(name: "Project 1")
        let project2 = Project(name: "Project 2")
        modelContext.insert(project1)
        modelContext.insert(project2)
        try modelContext.save()

        try repository.create(task: Task(title: "Task 1", project: project1))
        try repository.create(task: Task(title: "Task 2", project: project1))
        try repository.create(task: Task(title: "Task 3", project: project2))

        // When
        let project1Tasks = try repository.fetchByProject(project1)

        // Then
        XCTAssertEqual(project1Tasks.count, 2)
        XCTAssertTrue(project1Tasks.allSatisfy { $0.project?.id == project1.id })
    }

    func testFetchByTag() throws {
        // Given
        let tag1 = Tag(name: "urgent")
        let tag2 = Tag(name: "work")
        modelContext.insert(tag1)
        modelContext.insert(tag2)
        try modelContext.save()

        try repository.create(task: Task(title: "Task 1", tags: [tag1]))
        try repository.create(task: Task(title: "Task 2", tags: [tag1, tag2]))
        try repository.create(task: Task(title: "Task 3", tags: [tag2]))

        // When
        let tag1Tasks = try repository.fetchByTag(tag1)

        // Then
        XCTAssertEqual(tag1Tasks.count, 2)
        XCTAssertTrue(tag1Tasks.contains(where: { $0.title == "Task 1" }))
        XCTAssertTrue(tag1Tasks.contains(where: { $0.title == "Task 2" }))
    }

    func testFetchByCategory() throws {
        // Given
        let category1 = Category(name: "Shopping")
        let category2 = Category(name: "Work")
        modelContext.insert(category1)
        modelContext.insert(category2)
        try modelContext.save()

        try repository.create(task: Task(title: "Buy milk", category: category1))
        try repository.create(task: Task(title: "Buy eggs", category: category1))
        try repository.create(task: Task(title: "Email boss", category: category2))

        // When
        let shoppingTasks = try repository.fetchByCategory(category1)

        // Then
        XCTAssertEqual(shoppingTasks.count, 2)
        XCTAssertTrue(shoppingTasks.allSatisfy { $0.category?.id == category1.id })
    }

    func testFetchDueToday() throws {
        // Given
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        try repository.create(task: Task(
            title: "Due Today",
            dueDate: today.addingTimeInterval(3600), // 1 hour into today
            priority: .high
        ))
        try repository.create(task: Task(
            title: "Due Tomorrow",
            dueDate: tomorrow
        ))
        try repository.create(task: Task(
            title: "Due Yesterday",
            dueDate: yesterday
        ))

        // When
        let dueTodayTasks = try repository.fetchDueToday()

        // Then
        XCTAssertEqual(dueTodayTasks.count, 1)
        XCTAssertEqual(dueTodayTasks.first?.title, "Due Today")
    }

    func testFetchOverdue() throws {
        // Given
        let yesterday = Date(timeIntervalSinceNow: -86400)
        let tomorrow = Date(timeIntervalSinceNow: 86400)

        try repository.create(task: Task(
            title: "Overdue Task",
            dueDate: yesterday
        ))
        try repository.create(task: Task(
            title: "Future Task",
            dueDate: tomorrow
        ))
        let completedTask = Task(
            title: "Completed Overdue",
            completedAt: Date(),
            dueDate: yesterday
        )
        try repository.create(task: completedTask)

        // When
        let overdueTasks = try repository.fetchOverdue()

        // Then
        XCTAssertEqual(overdueTasks.count, 1)
        XCTAssertEqual(overdueTasks.first?.title, "Overdue Task")
    }

    func testSearch() throws {
        // Given
        try repository.create(task: Task(
            title: "Buy milk",
            notes: "From the grocery store"
        ))
        try repository.create(task: Task(
            title: "Email boss",
            notes: "About the project milk"
        ))
        try repository.create(task: Task(
            title: "Walk dog",
            notes: "In the park"
        ))

        // When
        let results = try repository.search(query: "milk")

        // Then
        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.contains(where: { $0.title == "Buy milk" }))
        XCTAssertTrue(results.contains(where: { $0.title == "Email boss" }))
    }

    // MARK: - Update Tests

    func testUpdateTask() throws {
        // Given
        let task = Task(title: "Original Title")
        try repository.create(task: task)

        // When
        task.title = "Updated Title"
        try repository.update(task: task)

        // Then
        let allTasks = try repository.fetchAll()
        XCTAssertEqual(allTasks.first?.title, "Updated Title")
        XCTAssertNotNil(allTasks.first?.updatedAt)
    }

    func testCompleteTask() throws {
        // Given
        let task = Task(title: "Task to Complete")
        try repository.create(task: task)
        XCTAssertNil(task.completedAt)

        // When
        try repository.complete(task: task)

        // Then
        XCTAssertEqual(task.status, .completed)
        XCTAssertNotNil(task.completedAt)
        XCTAssertNotNil(task.updatedAt)
    }

    // MARK: - Delete Tests

    func testDeleteTask() throws {
        // Given
        let task = Task(title: "Task to Delete")
        try repository.create(task: task)
        XCTAssertEqual(try repository.fetchAll().count, 1)

        // When
        try repository.delete(task: task)

        // Then
        XCTAssertEqual(try repository.fetchAll().count, 0)
    }

    // MARK: - Relationship Tests

    func testTaskWithSourceThought() throws {
        // Given
        let thought = Thought(source: .voice, rawText: "Buy milk and eggs")
        modelContext.insert(thought)
        try modelContext.save()

        let task = Task(title: "Buy milk and eggs", sourceThought: thought)

        // When
        try repository.create(task: task)

        // Then
        let allTasks = try repository.fetchAll()
        XCTAssertEqual(allTasks.first?.sourceThought?.id, thought.id)
        XCTAssertEqual(thought.derivedTasks?.count, 1)
    }

    func testTaskWithMultipleTags() throws {
        // Given
        let tag1 = Tag(name: "urgent")
        let tag2 = Tag(name: "work")
        let tag3 = Tag(name: "personal")
        modelContext.insert(tag1)
        modelContext.insert(tag2)
        modelContext.insert(tag3)
        try modelContext.save()

        let task = Task(title: "Important Task", tags: [tag1, tag2])

        // When
        try repository.create(task: task)

        // Then
        let fetchedTasks = try repository.fetchAll()
        XCTAssertEqual(fetchedTasks.first?.tags?.count, 2)

        let tag1Tasks = try repository.fetchByTag(tag1)
        let tag3Tasks = try repository.fetchByTag(tag3)
        XCTAssertEqual(tag1Tasks.count, 1)
        XCTAssertEqual(tag3Tasks.count, 0)
    }

    // MARK: - Performance Tests

    func testFetchPerformanceWith100Tasks() throws {
        // Given: Create 100 tasks with various statuses
        for i in 1...100 {
            let status: TaskStatus = [.inbox, .next, .waiting, .someday, .completed].randomElement()!
            try repository.create(task: Task(
                title: "Task \(i)",
                status: status
            ))
        }

        // When/Then: Measure fetch performance
        measure {
            _ = try? repository.fetchAll()
        }
    }
}
