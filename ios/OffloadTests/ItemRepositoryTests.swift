// Purpose: Unit tests for Offload.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep tests deterministic and avoid relying on network or time.

//  OffloadTests

import XCTest
import SwiftData
@testable import Offload


@MainActor
final class ItemRepositoryTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var repository: ItemRepository!

    override func setUp() async throws {
        let schema = Schema([
            Item.self,
            Collection.self,
            CollectionItem.self,
            Tag.self,
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = modelContainer.mainContext
        repository = ItemRepository(modelContext: modelContext)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        repository = nil
    }

    // MARK: - Create Tests

    func testCreateBasicItem() throws {
        let item = try repository.create(content: "Test item")

        XCTAssertEqual(item.content, "Test item")
        XCTAssertNil(item.type)
        XCTAssertFalse(item.isStarred)
        XCTAssertTrue(item.tags.isEmpty)
        XCTAssertNil(item.completedAt)

        let fetched = try repository.fetchAll()
        XCTAssertEqual(fetched.count, 1)
    }

    func testCreateItemWithType() throws {
        let item = try repository.create(type: "task", content: "Task item")

        XCTAssertEqual(item.type, "task")
        XCTAssertEqual(item.content, "Task item")
    }

    func testCreateStarredItem() throws {
        let item = try repository.create(content: "Important item", isStarred: true)

        XCTAssertTrue(item.isStarred)
    }

    func testCreateItemWithTags() throws {
        let urgent = Tag(name: "urgent")
        let work = Tag(name: "work")
        modelContext.insert(urgent)
        modelContext.insert(work)
        try modelContext.save()
        let item = try repository.create(content: "Tagged item", tags: [urgent, work])

        XCTAssertEqual(item.tags.count, 2)
        XCTAssertTrue(item.tags.contains(where: { $0.id == urgent.id }))
        XCTAssertTrue(item.tags.contains(where: { $0.id == work.id }))
    }

    func testCreateItemWithFollowUpDate() throws {
        let followUpDate = Date().addingTimeInterval(86400) // tomorrow
        let item = try repository.create(content: "Follow up item", followUpDate: followUpDate)

        XCTAssertNotNil(item.followUpDate)
        if let storedDate = item.followUpDate {
            XCTAssertEqual(storedDate.timeIntervalSince1970, followUpDate.timeIntervalSince1970, accuracy: 1.0)
        } else {
            XCTFail("Expected followUpDate to be set")
        }
    }

    // MARK: - Fetch Tests

    func testFetchAll() throws {
        try repository.create(content: "Item 1")
        try repository.create(content: "Item 2")
        try repository.create(content: "Item 3")

        let items = try repository.fetchAll()
        XCTAssertEqual(items.count, 3)
    }

    func testFetchAllSortedByCreatedAt() throws {
        let item1 = try repository.create(content: "First")
        Thread.sleep(forTimeInterval: 0.01)
        let item2 = try repository.create(content: "Second")
        Thread.sleep(forTimeInterval: 0.01)
        let item3 = try repository.create(content: "Third")

        let items = try repository.fetchAll()

        // Should be sorted in reverse chronological order (newest first)
        XCTAssertEqual(items[0].id, item3.id)
        XCTAssertEqual(items[1].id, item2.id)
        XCTAssertEqual(items[2].id, item1.id)
    }

    func testFetchById() throws {
        let item = try repository.create(content: "Find me")

        let fetched = try repository.fetchById(item.id)

        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.id, item.id)
        XCTAssertEqual(fetched?.content, "Find me")
    }

    func testFetchByIdNotFound() throws {
        let fetched = try repository.fetchById(UUID())
        XCTAssertNil(fetched)
    }

    func testFetchByType() throws {
        try repository.create(type: "task", content: "Task 1")
        try repository.create(type: "task", content: "Task 2")
        try repository.create(type: "link", content: "Link 1")
        try repository.create(content: "Capture")

        let tasks = try repository.fetchByType("task")
        XCTAssertEqual(tasks.count, 2)

        let links = try repository.fetchByType("link")
        XCTAssertEqual(links.count, 1)
    }

    func testFetchStarred() throws {
        try repository.create(content: "Not starred")
        try repository.create(content: "Starred 1", isStarred: true)
        try repository.create(content: "Starred 2", isStarred: true)

        let starred = try repository.fetchStarred()
        XCTAssertEqual(starred.count, 2)
        XCTAssertTrue(starred.allSatisfy { $0.isStarred })
    }

    func testFetchWithFollowUp() throws {
        let tomorrow = Date().addingTimeInterval(86400)
        let nextWeek = Date().addingTimeInterval(86400 * 7)

        try repository.create(content: "No follow up")
        try repository.create(content: "Follow up 1", followUpDate: nextWeek)
        try repository.create(content: "Follow up 2", followUpDate: tomorrow)

        let items = try repository.fetchWithFollowUp()
        XCTAssertEqual(items.count, 2)

        // Should be sorted by followUpDate (earliest first)
        XCTAssertEqual(items[0].content, "Follow up 2")
        XCTAssertEqual(items[1].content, "Follow up 1")
    }

    func testFetchByTag() throws {
        let work = Tag(name: "work")
        let urgent = Tag(name: "urgent")
        let personal = Tag(name: "personal")
        modelContext.insert(work)
        modelContext.insert(urgent)
        modelContext.insert(personal)
        try modelContext.save()

        try repository.create(content: "Item 1", tags: [work])
        try repository.create(content: "Item 2", tags: [work, urgent])
        try repository.create(content: "Item 3", tags: [personal])

        let workItems = try repository.fetchByTag(work)
        XCTAssertEqual(workItems.count, 2)

        let urgentItems = try repository.fetchByTag(urgent)
        XCTAssertEqual(urgentItems.count, 1)

        let personalItems = try repository.fetchByTag(personal)
        XCTAssertEqual(personalItems.count, 1)
    }

    func testSearchByContent() throws {
        try repository.create(content: "Buy groceries at the store")
        try repository.create(content: "Call dentist for appointment")
        try repository.create(content: "Review budget analysis")

        let results = try repository.searchByContent("budget")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].content, "Review budget analysis")
    }

    func testSearchByContentCaseInsensitive() throws {
        try repository.create(content: "IMPORTANT MEETING")
        try repository.create(content: "important call")
        try repository.create(content: "Something else")

        let results = try repository.searchByContent("important")
        XCTAssertEqual(results.count, 2)
    }

    func testFetchUncategorized() throws {
        try repository.create(content: "Capture 1")
        try repository.create(type: "task", content: "Task")
        try repository.create(content: "Capture 2")

        let captures = try repository.fetchUncategorized()
        XCTAssertEqual(captures.count, 2)
        XCTAssertTrue(captures.allSatisfy { $0.type == nil })
    }

    func testFetchCompleted() throws {
        let item1 = try repository.create(content: "Complete me")
        try repository.complete(item1)

        try repository.create(content: "Incomplete")

        let item2 = try repository.create(content: "Also complete")
        try repository.complete(item2)

        let completed = try repository.fetchCompleted()
        XCTAssertEqual(completed.count, 2)
        XCTAssertTrue(completed.allSatisfy { $0.completedAt != nil })
    }

    func testFetchIncomplete() throws {
        let item = try repository.create(content: "Complete this")
        try repository.complete(item)

        try repository.create(content: "Incomplete 1")
        try repository.create(content: "Incomplete 2")

        let incomplete = try repository.fetchIncomplete()
        XCTAssertEqual(incomplete.count, 2)
        XCTAssertTrue(incomplete.allSatisfy { $0.completedAt == nil })
    }

    func testFetchCaptures() throws {
        // Captures are type=nil AND not completed
        try repository.create(content: "Active capture")

        let completed = try repository.create(content: "Completed capture")
        try repository.complete(completed)

        try repository.create(type: "task", content: "Task")

        let captures = try repository.fetchCaptureItems()
        XCTAssertEqual(captures.count, 1)
        XCTAssertEqual(captures[0].content, "Active capture")
    }

    func testFetchCaptureItemsPage() throws {
        let base = Date()
        let item1 = try repository.create(content: "Older")
        let item2 = try repository.create(content: "Middle")
        let item3 = try repository.create(content: "Newest")

        item1.createdAt = base.addingTimeInterval(-30)
        item2.createdAt = base.addingTimeInterval(-10)
        item3.createdAt = base
        try modelContext.save()

        let firstPage = try repository.fetchCaptureItems(limit: 2, offset: 0)
        XCTAssertEqual(firstPage.map(\.id), [item3.id, item2.id])

        let secondPage = try repository.fetchCaptureItems(limit: 2, offset: 2)
        XCTAssertEqual(secondPage.map(\.id), [item1.id])
    }

    // MARK: - Update Tests

    func testUpdate() throws {
        let item = try repository.create(content: "Original")

        item.content = "Modified"
        try repository.update(item)

        let fetched = try repository.fetchById(item.id)
        XCTAssertEqual(fetched?.content, "Modified")
    }

    func testUpdateType() throws {
        let item = try repository.create(content: "Item")
        XCTAssertNil(item.type)

        try repository.updateType(item, type: "task")
        XCTAssertEqual(item.type, "task")

        let fetched = try repository.fetchById(item.id)
        XCTAssertEqual(fetched?.type, "task")
    }

    func testUpdateContent() throws {
        let item = try repository.create(content: "Old content")

        try repository.updateContent(item, content: "New content")

        XCTAssertEqual(item.content, "New content")

        let fetched = try repository.fetchById(item.id)
        XCTAssertEqual(fetched?.content, "New content")
    }

    func testToggleStar() throws {
        let item = try repository.create(content: "Item")
        XCTAssertFalse(item.isStarred)

        try repository.toggleStar(item)
        XCTAssertTrue(item.isStarred)

        try repository.toggleStar(item)
        XCTAssertFalse(item.isStarred)
    }

    func testAddTag() throws {
        let item = try repository.create(content: "Item")
        XCTAssertTrue(item.tags.isEmpty)

        let urgent = Tag(name: "urgent")
        let work = Tag(name: "work")
        modelContext.insert(urgent)
        modelContext.insert(work)
        try modelContext.save()

        try repository.addTag(item, tag: urgent)
        XCTAssertEqual(item.tags.count, 1)
        XCTAssertTrue(item.tags.contains(where: { $0.id == urgent.id }))

        try repository.addTag(item, tag: work)
        XCTAssertEqual(item.tags.count, 2)
        XCTAssertTrue(item.tags.contains(where: { $0.id == work.id }))
    }

    func testAddDuplicateTag() throws {
        let urgent = Tag(name: "urgent")
        modelContext.insert(urgent)
        try modelContext.save()
        let item = try repository.create(content: "Item", tags: [urgent])

        try repository.addTag(item, tag: urgent)

        // Should not add duplicate
        XCTAssertEqual(item.tags.count, 1)
    }

    func testRemoveTag() throws {
        let urgent = Tag(name: "urgent")
        let work = Tag(name: "work")
        let personal = Tag(name: "personal")
        modelContext.insert(urgent)
        modelContext.insert(work)
        modelContext.insert(personal)
        try modelContext.save()
        let item = try repository.create(content: "Item", tags: [urgent, work, personal])

        try repository.removeTag(item, tag: work)

        XCTAssertEqual(item.tags.count, 2)
        XCTAssertFalse(item.tags.contains(where: { $0.id == work.id }))
        XCTAssertTrue(item.tags.contains(where: { $0.id == urgent.id }))
        XCTAssertTrue(item.tags.contains(where: { $0.id == personal.id }))
    }

    func testUpdateFollowUpDate() throws {
        let item = try repository.create(content: "Item")
        XCTAssertNil(item.followUpDate)

        let tomorrow = Date().addingTimeInterval(86400)
        try repository.updateFollowUpDate(item, date: tomorrow)

        XCTAssertNotNil(item.followUpDate)
        if let storedDate = item.followUpDate {
            XCTAssertEqual(storedDate.timeIntervalSince1970, tomorrow.timeIntervalSince1970, accuracy: 1.0)
        } else {
            XCTFail("Expected followUpDate to be set")
        }

        // Can clear follow up date
        try repository.updateFollowUpDate(item, date: nil)
        XCTAssertNil(item.followUpDate)
    }

    func testComplete() throws {
        let item = try repository.create(content: "Task")
        XCTAssertNil(item.completedAt)
        XCTAssertFalse(item.isCompleted)

        try repository.complete(item)

        XCTAssertNotNil(item.completedAt)
        XCTAssertTrue(item.isCompleted)
    }

    func testUncomplete() throws {
        let item = try repository.create(content: "Task")
        try repository.complete(item)

        XCTAssertNotNil(item.completedAt)

        try repository.uncomplete(item)

        XCTAssertNil(item.completedAt)
        XCTAssertFalse(item.isCompleted)
    }

    func testToggleCompletion() throws {
        let item = try repository.create(content: "Task")
        XCTAssertNil(item.completedAt)

        try repository.toggleCompletion(item)
        XCTAssertNotNil(item.completedAt)
        XCTAssertTrue(item.isCompleted)

        try repository.toggleCompletion(item)
        XCTAssertNil(item.completedAt)
        XCTAssertFalse(item.isCompleted)
    }

    func testMarkCompleted() throws {
        let item = try repository.create(content: "Task")
        XCTAssertNil(item.completedAt)

        try repository.markCompleted(item)
        XCTAssertNotNil(item.completedAt)

        let firstCompletion = item.completedAt
        try repository.markCompleted(item)
        XCTAssertEqual(item.completedAt, firstCompletion)
    }

    func testMarkAllCompleted() throws {
        let item1 = try repository.create(content: "Task 1")
        let item2 = try repository.create(content: "Task 2")
        let item3 = try repository.create(content: "Task 3")

        try repository.markAllCompleted([item1, item2, item3])

        XCTAssertNotNil(item1.completedAt)
        XCTAssertNotNil(item2.completedAt)
        XCTAssertNotNil(item3.completedAt)
    }

    func testMoveToCollection() throws {
        let collectionRepository = CollectionRepository(modelContext: modelContext)
        let collection = try collectionRepository.create(name: "Plan", isStructured: true)
        let item = try repository.create(content: "Move me")

        try repository.moveToCollection(item, collection: collection, position: 0)

        let fetchedCollection = try collectionRepository.fetchById(collection.id)
        XCTAssertEqual(fetchedCollection?.collectionItems?.count, 1)
        XCTAssertEqual(fetchedCollection?.collectionItems?.first?.itemId, item.id)
    }

    func testValidate() throws {
        let item = try repository.create(content: "  ")
        XCTAssertFalse(try repository.validate(item))

        try repository.updateContent(item, content: "Valid")
        XCTAssertTrue(try repository.validate(item))
    }

    // MARK: - Delete Tests

    func testDelete() throws {
        let item = try repository.create(content: "Delete me")

        XCTAssertEqual(try repository.fetchAll().count, 1)

        try repository.delete(item)

        XCTAssertEqual(try repository.fetchAll().count, 0)
    }

    func testDeleteMultiple() throws {
        let item1 = try repository.create(content: "Item 1")
        let item2 = try repository.create(content: "Item 2")
        let item3 = try repository.create(content: "Item 3")

        XCTAssertEqual(try repository.fetchAll().count, 3)

        try repository.deleteMultiple([item1, item3])

        let remaining = try repository.fetchAll()
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining[0].id, item2.id)
    }

    func testDeleteAll() throws {
        let item1 = try repository.create(content: "Item 1")
        let item2 = try repository.create(content: "Item 2")

        try repository.deleteAll([item1, item2])

        XCTAssertEqual(try repository.fetchAll().count, 0)
    }
}
