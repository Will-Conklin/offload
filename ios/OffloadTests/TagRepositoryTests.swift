// Purpose: Unit tests for tag repository behavior.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep tests deterministic and avoid relying on network or time.

import XCTest
import SwiftData
@testable import Offload


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

    func testUpdateUsageCount() throws {
        let tag = try tagRepository.fetchOrCreate("urgent")
        _ = try itemRepository.create(content: "Item 1", tags: [tag])
        _ = try itemRepository.create(content: "Item 2", tags: [tag])

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
}
