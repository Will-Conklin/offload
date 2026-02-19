// Purpose: Unit tests for collection item repository behavior.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep tests deterministic and avoid relying on network or time.

@testable import Offload
import SwiftData
import XCTest

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

    func testAddItemToCollection_AppendsUsingMaxPositionWhenStructured() throws {
        let collection = try collectionRepository.create(name: "Plan", isStructured: true)
        let item1 = try itemRepository.create(content: "Item 1")
        let item2 = try itemRepository.create(content: "Item 2")
        let item3 = try itemRepository.create(content: "Item 3")

        _ = try collectionItemRepository.addItemToCollection(
            itemId: item1.id,
            collectionId: collection.id,
            position: 0
        )
        _ = try collectionItemRepository.addItemToCollection(
            itemId: item2.id,
            collectionId: collection.id,
            position: 2
        )
        let appended = try collectionItemRepository.addItemToCollection(
            itemId: item3.id,
            collectionId: collection.id
        )

        XCTAssertEqual(appended.position, 3)
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

    func testReorderItems_LargeStructuredDataset_AssignsContiguousPositions() throws {
        let collection = try collectionRepository.create(name: "Plan", isStructured: true)
        var itemIDs: [UUID] = []
        for index in 0 ..< 500 {
            let item = try itemRepository.create(content: "Item \(index)")
            _ = try collectionItemRepository.addItemToCollection(
                itemId: item.id,
                collectionId: collection.id,
                position: index
            )
            itemIDs.append(item.id)
        }

        let reordered = Array(itemIDs.reversed())
        try collectionItemRepository.reorderItems(collection.id, itemIds: reordered)

        let fetched = try collectionRepository.fetchById(collection.id)
        let positions = fetched?.collectionItems?.reduce(into: [UUID: Int]()) { result, collectionItem in
            if let position = collectionItem.position {
                result[collectionItem.itemId] = position
            }
        }
        XCTAssertEqual(positions?.count, reordered.count)
        for (expectedPosition, itemId) in reordered.enumerated() {
            XCTAssertEqual(positions?[itemId], expectedPosition)
        }
    }

    func testReorderForCollection_UnstructuredUsesItemCreatedAtOrder() throws {
        let collection = try collectionRepository.create(name: "List", isStructured: false)
        let base = Date()
        let item1 = try itemRepository.create(content: "Oldest")
        let item2 = try itemRepository.create(content: "Middle")
        let item3 = try itemRepository.create(content: "Newest")
        item1.createdAt = base.addingTimeInterval(-30)
        item2.createdAt = base.addingTimeInterval(-10)
        item3.createdAt = base
        try modelContext.save()

        _ = try collectionItemRepository.addItemToCollection(
            itemId: item1.id,
            collectionId: collection.id,
            position: 8
        )
        _ = try collectionItemRepository.addItemToCollection(
            itemId: item2.id,
            collectionId: collection.id,
            position: 3
        )
        _ = try collectionItemRepository.addItemToCollection(
            itemId: item3.id,
            collectionId: collection.id,
            position: 0
        )

        try collectionItemRepository.reorder(for: collection)

        let fetched = try collectionRepository.fetchById(collection.id)
        let positions = fetched?.collectionItems?.reduce(into: [UUID: Int]()) { result, collectionItem in
            if let position = collectionItem.position {
                result[collectionItem.itemId] = position
            }
        }
        XCTAssertEqual(positions?[item1.id], 0)
        XCTAssertEqual(positions?[item2.id], 1)
        XCTAssertEqual(positions?[item3.id], 2)
    }

    func testRemoveItemFromCollection_CompactsStructuredSiblingPositions() throws {
        let collection = try collectionRepository.create(name: "Plan", isStructured: true)
        let item1 = try itemRepository.create(content: "Item 1")
        let item2 = try itemRepository.create(content: "Item 2")
        let item3 = try itemRepository.create(content: "Item 3")

        _ = try collectionItemRepository.addItemToCollection(
            itemId: item1.id,
            collectionId: collection.id,
            position: 0
        )
        let removable = try collectionItemRepository.addItemToCollection(
            itemId: item2.id,
            collectionId: collection.id,
            position: 1
        )
        _ = try collectionItemRepository.addItemToCollection(
            itemId: item3.id,
            collectionId: collection.id,
            position: 2
        )

        try collectionItemRepository.removeItemFromCollection(removable)

        let fetched = try collectionRepository.fetchById(collection.id)
        let positions = fetched?.collectionItems?.reduce(into: [UUID: Int]()) { result, collectionItem in
            if let position = collectionItem.position {
                result[collectionItem.itemId] = position
            }
        }
        XCTAssertEqual(positions?[item1.id], 0)
        XCTAssertEqual(positions?[item3.id], 1)
    }

    func testFetchPageStructuredUsesPosition() throws {
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

        let page = try collectionItemRepository.fetchPage(
            collectionId: collection.id,
            isStructured: true,
            limit: 2,
            offset: 0
        )
        XCTAssertEqual(page.map(\.itemId), [item2.id, item3.id])
    }

    func testFetchPageUnstructuredUsesItemCreatedAt() throws {
        let collection = try collectionRepository.create(name: "List", isStructured: false)
        let base = Date()
        let item1 = try itemRepository.create(content: "Oldest")
        let item2 = try itemRepository.create(content: "Middle")
        let item3 = try itemRepository.create(content: "Newest")

        item1.createdAt = base.addingTimeInterval(-30)
        item2.createdAt = base.addingTimeInterval(-10)
        item3.createdAt = base
        try modelContext.save()

        _ = try collectionItemRepository.addItemToCollection(
            itemId: item1.id,
            collectionId: collection.id
        )
        _ = try collectionItemRepository.addItemToCollection(
            itemId: item2.id,
            collectionId: collection.id
        )
        _ = try collectionItemRepository.addItemToCollection(
            itemId: item3.id,
            collectionId: collection.id
        )

        let page = try collectionItemRepository.fetchPage(
            collectionId: collection.id,
            isStructured: false,
            limit: 2,
            offset: 0
        )
        XCTAssertEqual(page.map(\.itemId), [item1.id, item2.id])
    }

    func testAddItemToCollection_ThrowsWhenCollectionNotFound() async throws {
        let item = try itemRepository.create(content: "Test Item")
        let invalidCollectionId = UUID()

        do {
            _ = try collectionItemRepository.addItemToCollection(
                itemId: item.id,
                collectionId: invalidCollectionId
            )
            XCTFail("Expected ValidationError to be thrown")
        } catch let error as ValidationError {
            XCTAssertEqual(error.message, "Collection not found")
        } catch {
            XCTFail("Expected ValidationError but got \(error)")
        }
    }

    func testAddItemToCollection_ThrowsWhenItemNotFound() async throws {
        let collection = try collectionRepository.create(name: "Test Plan", isStructured: true)
        let invalidItemId = UUID()

        do {
            _ = try collectionItemRepository.addItemToCollection(
                itemId: invalidItemId,
                collectionId: collection.id
            )
            XCTFail("Expected ValidationError to be thrown")
        } catch let error as ValidationError {
            XCTAssertEqual(error.message, "Item not found")
        } catch {
            XCTFail("Expected ValidationError but got \(error)")
        }
    }

    func testMoveItemToCollection_ThrowsWhenCollectionNotFound() async throws {
        let collection1 = try collectionRepository.create(name: "Plan 1", isStructured: true)
        let item = try itemRepository.create(content: "Test Item")
        let collectionItem = try collectionItemRepository.addItemToCollection(
            itemId: item.id,
            collectionId: collection1.id
        )

        let invalidCollectionId = UUID()

        do {
            try collectionItemRepository.moveItemToCollection(
                collectionItem: collectionItem,
                toCollectionId: invalidCollectionId
            )
            XCTFail("Expected ValidationError to be thrown")
        } catch let error as ValidationError {
            XCTAssertEqual(error.message, "Collection not found")
        } catch {
            XCTFail("Expected ValidationError but got \(error)")
        }
    }

    func testSavePersistsBatchPositionUpdates() throws {
        let collection = try collectionRepository.create(name: "Plan", isStructured: true)
        let item1 = try itemRepository.create(content: "Item 1")
        let item2 = try itemRepository.create(content: "Item 2")

        let ci1 = try collectionItemRepository.addItemToCollection(
            itemId: item1.id, collectionId: collection.id, position: 0
        )
        let ci2 = try collectionItemRepository.addItemToCollection(
            itemId: item2.id, collectionId: collection.id, position: 1
        )

        // Batch-update positions directly (simulating view reorder)
        ci1.position = 1
        ci2.position = 0

        // Use repository save instead of direct modelContext access
        try collectionItemRepository.save()

        // Verify persisted order
        let fetched = try collectionItemRepository.fetchByCollection(collection.id)
        let sorted = fetched.sorted { ($0.position ?? 0) < ($1.position ?? 0) }
        XCTAssertEqual(sorted.first?.itemId, item2.id)
        XCTAssertEqual(sorted.last?.itemId, item1.id)
    }

    func testSavePersistsBatchParentAndPositionUpdates() throws {
        let collection = try collectionRepository.create(name: "Plan", isStructured: true)
        let parentItem = try itemRepository.create(content: "Parent")
        let childItem = try itemRepository.create(content: "Child")

        let parentCollectionItem = try collectionItemRepository.addItemToCollection(
            itemId: parentItem.id,
            collectionId: collection.id,
            position: 0
        )
        let childCollectionItem = try collectionItemRepository.addItemToCollection(
            itemId: childItem.id,
            collectionId: collection.id,
            position: 1
        )

        // Batch-update hierarchy and ordering directly (simulating drag/nest).
        childCollectionItem.parentId = parentCollectionItem.id
        childCollectionItem.position = 0

        try collectionItemRepository.save()

        let persistedChild = try collectionItemRepository.fetchById(childCollectionItem.id)
        XCTAssertEqual(persistedChild?.parentId, parentCollectionItem.id)
        XCTAssertEqual(persistedChild?.position, 0)
    }

    func testHasChildrenReturnsTrueOnlyForItemsWithChildren() throws {
        let collection = try collectionRepository.create(name: "Plan", isStructured: true)
        let parentItem = try itemRepository.create(content: "Parent")
        let childItem = try itemRepository.create(content: "Child")

        let parentCollectionItem = try collectionItemRepository.addItemToCollection(
            itemId: parentItem.id,
            collectionId: collection.id,
            position: 0
        )
        let childCollectionItem = try collectionItemRepository.addItemToCollection(
            itemId: childItem.id,
            collectionId: collection.id,
            position: 1,
            parentId: parentCollectionItem.id
        )

        XCTAssertTrue(collectionItemRepository.hasChildren(parentCollectionItem.id))
        XCTAssertFalse(collectionItemRepository.hasChildren(childCollectionItem.id))
    }
}
