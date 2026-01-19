// Purpose: Unit tests for collection item repository behavior.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep tests deterministic and avoid relying on network or time.

import XCTest
import SwiftData
@testable import Offload


@MainActor
final class CollectionItemRepositoryTests: XCTestCase {
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var collectionRepository: CollectionRepository!
    private var itemRepository: ItemRepository!
    private var collectionItemRepository: CollectionItemRepository!

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
        collectionItemRepository = CollectionItemRepository(modelContext: modelContext)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        collectionRepository = nil
        itemRepository = nil
        collectionItemRepository = nil
    }

    func testAddItemToCollection() throws {
        let collection = try collectionRepository.create(name: "Plan", isStructured: true)
        let item = try itemRepository.create(content: "Item 1")

        let collectionItem = try collectionItemRepository.addItemToCollection(
            itemId: item.id,
            collectionId: collection.id,
            position: 0
        )

        XCTAssertEqual(collectionItem.collectionId, collection.id)
        XCTAssertEqual(collectionItem.itemId, item.id)
        XCTAssertEqual(collectionItem.position, 0)
    }

    func testReorderForCollection() throws {
        let collection = try collectionRepository.create(name: "Plan", isStructured: true)
        let item1 = try itemRepository.create(content: "Item 1")
        let item2 = try itemRepository.create(content: "Item 2")
        let item3 = try itemRepository.create(content: "Item 3")

        _ = try collectionItemRepository.addItemToCollection(
            itemId: item1.id,
            collectionId: collection.id,
            position: 2
        )
        _ = try collectionItemRepository.addItemToCollection(
            itemId: item2.id,
            collectionId: collection.id,
            position: 0
        )
        _ = try collectionItemRepository.addItemToCollection(
            itemId: item3.id,
            collectionId: collection.id,
            position: 1
        )

        try collectionItemRepository.reorder(for: collection)

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
