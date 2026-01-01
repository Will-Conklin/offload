//
//  CategoryRepositoryTests.swift
//  OffloadTests
//
//  Created by Claude Code on 12/31/25.
//

import XCTest
import SwiftData
@testable import offload

@MainActor
final class CategoryRepositoryTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var repository: CategoryRepository!
    var taskRepository: TaskRepository!

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
        repository = CategoryRepository(modelContext: modelContext)
        taskRepository = TaskRepository(modelContext: modelContext)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        repository = nil
        taskRepository = nil
    }

    func testCreateCategory() throws {
        let category = Category(name: "Work", icon: "💼")

        try repository.create(category: category)

        let fetched = try repository.fetchAll()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "Work")
        XCTAssertEqual(fetched.first?.icon, "💼")
    }

    func testFetchByName() throws {
        let category1 = Category(name: "Work")
        let category2 = Category(name: "Personal")

        try repository.create(category: category1)
        try repository.create(category: category2)

        let fetched = try repository.fetchByName("Work")
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.name, "Work")
    }

    func testSearchCategories() throws {
        let category1 = Category(name: "Work Projects")
        let category2 = Category(name: "Personal")
        let category3 = Category(name: "Work Tasks")

        try repository.create(category: category1)
        try repository.create(category: category2)
        try repository.create(category: category3)

        let results = try repository.search(query: "Work")
        XCTAssertEqual(results.count, 2)
    }

    func testFindOrCreateExisting() throws {
        let category = Category(name: "Work")
        try repository.create(category: category)

        let found = try repository.findOrCreate(name: "Work")
        XCTAssertEqual(found.id, category.id)

        // Should not create duplicate
        let allCategories = try repository.fetchAll()
        XCTAssertEqual(allCategories.count, 1)
    }

    func testFindOrCreateNew() throws {
        let category = try repository.findOrCreate(name: "Work", icon: "💼")

        XCTAssertEqual(category.name, "Work")
        XCTAssertEqual(category.icon, "💼")

        let allCategories = try repository.fetchAll()
        XCTAssertEqual(allCategories.count, 1)
    }

    func testUpdateCategory() throws {
        let category = Category(name: "Work")
        try repository.create(category: category)

        category.icon = "💼"
        try repository.update(category: category)

        let fetched = try repository.fetchById(category.id)
        XCTAssertEqual(fetched?.icon, "💼")
    }

    func testDeleteCategory() throws {
        let category = Category(name: "Work")
        try repository.create(category: category)

        XCTAssertEqual(try repository.fetchAll().count, 1)

        try repository.delete(category: category)
        XCTAssertEqual(try repository.fetchAll().count, 0)
    }

    func testGetTaskCount() throws {
        let category = Category(name: "Work")
        try repository.create(category: category)

        XCTAssertEqual(repository.getTaskCount(category: category), 0)

        let task1 = Task(title: "Task 1", category: category)
        let task2 = Task(title: "Task 2", category: category)

        try taskRepository.create(task: task1)
        try taskRepository.create(task: task2)

        XCTAssertEqual(repository.getTaskCount(category: category), 2)
    }

    func testIsCategoryInUse() throws {
        let category = Category(name: "Work")
        try repository.create(category: category)

        XCTAssertFalse(repository.isCategoryInUse(category: category))

        let task = Task(title: "Task 1", category: category)
        try taskRepository.create(task: task)

        XCTAssertTrue(repository.isCategoryInUse(category: category))
    }

    func testFetchAllSortedByName() throws {
        let category1 = Category(name: "Zebra")
        let category2 = Category(name: "Alpha")
        let category3 = Category(name: "Middle")

        try repository.create(category: category1)
        try repository.create(category: category2)
        try repository.create(category: category3)

        let sorted = try repository.fetchAll()
        XCTAssertEqual(sorted[0].name, "Alpha")
        XCTAssertEqual(sorted[1].name, "Middle")
        XCTAssertEqual(sorted[2].name, "Zebra")
    }
}
