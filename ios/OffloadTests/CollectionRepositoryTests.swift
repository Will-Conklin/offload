// Purpose: Unit tests for collection repository behavior.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep tests deterministic and avoid relying on network or time.

import XCTest
import SwiftData
@testable import Offload


@MainActor
final class CollectionRepositoryTests: XCTestCase {
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var collectionRepository: CollectionRepository!
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
        collectionRepository = CollectionRepository(modelContext: modelContext)
        itemRepository = ItemRepository(modelContext: modelContext)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        collectionRepository = nil
        itemRepository = nil
    }

    func testFetchWithItems() throws {
        let collection = try collectionRepository.create(name: "Plan", isStructured: true)
        let item = try itemRepository.create(content: "Item 1")
        try collectionRepository.addItem(item, to: collection, position: 0)

        let collections = try collectionRepository.fetchWithItems()
        XCTAssertEqual(collections.count, 1)
        XCTAssertEqual(collections.first?.collectionItems?.count, 1)
    }

    func testAddAndRemoveItem() throws {
        let collection = try collectionRepository.create(name: "List", isStructured: false)
        let item = try itemRepository.create(content: "Item 1")

        try collectionRepository.addItem(item, to: collection)
        var fetched = try collectionRepository.fetchById(collection.id)
        XCTAssertEqual(fetched?.collectionItems?.count, 1)

        try collectionRepository.removeItem(item, from: collection)
        fetched = try collectionRepository.fetchById(collection.id)
        XCTAssertEqual(fetched?.collectionItems?.count ?? 0, 0)
    }

    func testReorderItems() throws {
        let collection = try collectionRepository.create(name: "Plan", isStructured: true)
        let item1 = try itemRepository.create(content: "Item 1")
        let item2 = try itemRepository.create(content: "Item 2")
        let item3 = try itemRepository.create(content: "Item 3")

        try collectionRepository.addItem(item1, to: collection, position: 0)
        try collectionRepository.addItem(item2, to: collection, position: 1)
        try collectionRepository.addItem(item3, to: collection, position: 2)

        try collectionRepository.reorderItems([item2, item3, item1], in: collection)

        let fetched = try collectionRepository.fetchById(collection.id)
        let positions = fetched?.collectionItems?.reduce(into: [UUID: Int]()) { result, collectionItem in
            if let position = collectionItem.position {
                result[collectionItem.itemId] = position
            }
        }
        XCTAssertEqual(positions?[item2.id], 0)
        XCTAssertEqual(positions?[item3.id], 1)
        XCTAssertEqual(positions?[item1.id], 2)
    }
}
