// Purpose: Unit tests for tag repository behavior.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep tests deterministic and avoid relying on network or time.

@testable import Offload
import SwiftData
import XCTest

@MainActor
final class TagRepositoryTests: XCTestCase {
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var tagRepository: TagRepository!
    private var itemRepository: ItemRepository!

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
        tagRepository = TagRepository(modelContext: modelContext)
        itemRepository = ItemRepository(modelContext: modelContext)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        tagRepository = nil
        itemRepository = nil
    }

    func testFetchOrCreate() throws {
        let first = try tagRepository.fetchOrCreate("work")
        let second = try tagRepository.fetchOrCreate("work")

        XCTAssertEqual(first.id, second.id)
    }

    func testFetchOrCreateNormalizesCaseAndWhitespace() throws {
        let first = try tagRepository.fetchOrCreate("  Work  ")
        let second = try tagRepository.fetchOrCreate("work")

        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(first.name, "Work")
    }

    func testUpdateUsageCount() throws {
        let tag = try tagRepository.fetchOrCreate("urgent")
        _ = try itemRepository.create(content: "Item 1", tags: [tag])
        _ = try itemRepository.create(content: "Item 2", tags: [tag])

        let count = try tagRepository.updateUsageCount(tag)
        XCTAssertEqual(count, 2)
    }

    func testUpdateUsageCount_IncludesCollectionUsage() throws {
        let tag = try tagRepository.fetchOrCreate("project")
        _ = try itemRepository.create(content: "Item 1", tags: [tag])

        let collection = Collection(name: "Plan", isStructured: true, tags: [tag])
        modelContext.insert(collection)
        try modelContext.save()

        let count = try tagRepository.updateUsageCount(tag)
        XCTAssertEqual(count, 2)
    }

    func testFetchUnused() throws {
        let unused = try tagRepository.fetchOrCreate("unused")
        let used = try tagRepository.fetchOrCreate("used")
        _ = try itemRepository.create(content: "Item 1", tags: [used])

        let unusedTags = try tagRepository.fetchUnused()
        XCTAssertTrue(unusedTags.contains(where: { $0.id == unused.id }))
        XCTAssertFalse(unusedTags.contains(where: { $0.id == used.id }))
    }

    func testFetchUnused_ExcludesCollectionOnlyTags() throws {
        let unused = try tagRepository.fetchOrCreate("unused")
        let collectionTag = try tagRepository.fetchOrCreate("collection-only")

        let collection = Collection(name: "List", isStructured: false, tags: [collectionTag])
        modelContext.insert(collection)
        try modelContext.save()

        let unusedTags = try tagRepository.fetchUnused()
        XCTAssertTrue(unusedTags.contains(where: { $0.id == unused.id }))
        XCTAssertFalse(unusedTags.contains(where: { $0.id == collectionTag.id }))
    }

    func testIsTagInUse_TrueForCollectionOnlyTag() throws {
        let tag = try tagRepository.fetchOrCreate("in-use")
        let collection = Collection(name: "Plan", isStructured: true, tags: [tag])
        modelContext.insert(collection)
        try modelContext.save()

        XCTAssertTrue(tagRepository.isTagInUse(tag: tag))
    }
}
