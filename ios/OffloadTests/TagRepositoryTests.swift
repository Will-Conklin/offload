//
//  TagRepositoryTests.swift
//  OffloadTests
//
//  Created by Claude Code on 12/31/25.
//

import XCTest
import SwiftData
@testable import offload

@MainActor
final class TagRepositoryTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var repository: TagRepository!
    var taskRepository: TaskRepository!

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
        repository = TagRepository(modelContext: modelContext)
        taskRepository = TaskRepository(modelContext: modelContext)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        repository = nil
        taskRepository = nil
    }

    func testCreateTag() throws {
        let tag = Tag(name: "urgent", color: "#FF0000")

        try repository.create(tag: tag)

        let fetched = try repository.fetchAll()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "urgent")
        XCTAssertEqual(fetched.first?.color, "#FF0000")
    }

    func testFetchByName() throws {
        let tag1 = Tag(name: "urgent")
        let tag2 = Tag(name: "work")

        try repository.create(tag: tag1)
        try repository.create(tag: tag2)

        let fetched = try repository.fetchByName("urgent")
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.name, "urgent")
    }

    func testSearchTags() throws {
        let tag1 = Tag(name: "work-urgent")
        let tag2 = Tag(name: "personal")
        let tag3 = Tag(name: "work-project")

        try repository.create(tag: tag1)
        try repository.create(tag: tag2)
        try repository.create(tag: tag3)

        let results = try repository.search(query: "work")
        XCTAssertEqual(results.count, 2)
    }

    func testFindOrCreateExisting() throws {
        let tag = Tag(name: "urgent")
        try repository.create(tag: tag)

        let found = try repository.findOrCreate(name: "urgent")
        XCTAssertEqual(found.id, tag.id)

        // Should not create duplicate
        let allTags = try repository.fetchAll()
        XCTAssertEqual(allTags.count, 1)
    }

    func testFindOrCreateNew() throws {
        let tag = try repository.findOrCreate(name: "urgent", color: "#FF0000")

        XCTAssertEqual(tag.name, "urgent")
        XCTAssertEqual(tag.color, "#FF0000")

        let allTags = try repository.fetchAll()
        XCTAssertEqual(allTags.count, 1)
    }

    func testUpdateTag() throws {
        let tag = Tag(name: "urgent")
        try repository.create(tag: tag)

        tag.color = "#FF0000"
        try repository.update(tag: tag)

        let fetched = try repository.fetchById(tag.id)
        XCTAssertEqual(fetched?.color, "#FF0000")
    }

    func testDeleteTag() throws {
        let tag = Tag(name: "urgent")
        try repository.create(tag: tag)

        XCTAssertEqual(try repository.fetchAll().count, 1)

        try repository.delete(tag: tag)
        XCTAssertEqual(try repository.fetchAll().count, 0)
    }

    func testGetTaskCount() throws {
        let tag = Tag(name: "urgent")
        try repository.create(tag: tag)

        XCTAssertEqual(repository.getTaskCount(tag: tag), 0)

        let task1 = Task(title: "Task 1", tags: [tag])
        let task2 = Task(title: "Task 2", tags: [tag])

        try taskRepository.create(task: task1)
        try taskRepository.create(task: task2)

        XCTAssertEqual(repository.getTaskCount(tag: tag), 2)
    }

    func testIsTagInUse() throws {
        let tag = Tag(name: "urgent")
        try repository.create(tag: tag)

        XCTAssertFalse(repository.isTagInUse(tag: tag))

        let task = Task(title: "Task 1", tags: [tag])
        try taskRepository.create(task: task)

        XCTAssertTrue(repository.isTagInUse(tag: tag))
    }

    func testFetchAllSortedByName() throws {
        let tag1 = Tag(name: "zebra")
        let tag2 = Tag(name: "alpha")
        let tag3 = Tag(name: "middle")

        try repository.create(tag: tag1)
        try repository.create(tag: tag2)
        try repository.create(tag: tag3)

        let sorted = try repository.fetchAll()
        XCTAssertEqual(sorted[0].name, "alpha")
        XCTAssertEqual(sorted[1].name, "middle")
        XCTAssertEqual(sorted[2].name, "zebra")
    }
}
