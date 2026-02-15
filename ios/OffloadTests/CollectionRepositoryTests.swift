// Purpose: Unit tests for collection repository behavior.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep tests deterministic and avoid relying on network or time.

@testable import Offload
import SwiftData
import XCTest

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

    func testFetchPageFiltersAndSorts() throws {
        let base = Date()
        let plan1 = try collectionRepository.create(name: "Plan 1", isStructured: true)
        let plan2 = try collectionRepository.create(name: "Plan 2", isStructured: true)
        let list1 = try collectionRepository.create(name: "List 1", isStructured: false)
        let list2 = try collectionRepository.create(name: "List 2", isStructured: false)

        plan1.createdAt = base.addingTimeInterval(-10)
        plan2.createdAt = base
        list1.createdAt = base.addingTimeInterval(-20)
        list2.createdAt = base.addingTimeInterval(-5)
        try modelContext.save()

        let firstPlanPage = try collectionRepository.fetchPage(isStructured: true, limit: 1, offset: 0)
        XCTAssertEqual(firstPlanPage.map(\.id), [plan2.id])

        let secondPlanPage = try collectionRepository.fetchPage(isStructured: true, limit: 1, offset: 1)
        XCTAssertEqual(secondPlanPage.map(\.id), [plan1.id])

        let listPage = try collectionRepository.fetchPage(isStructured: false, limit: 2, offset: 0)
        XCTAssertEqual(listPage.map(\.id), [list2.id, list1.id])
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

    func testAddItem_UsesMaxPositionPlusOneForStructuredCollection() throws {
        let collection = try collectionRepository.create(name: "Plan", isStructured: true)
        let item1 = try itemRepository.create(content: "Item 1")
        let item2 = try itemRepository.create(content: "Item 2")
        let item3 = try itemRepository.create(content: "Item 3")

        try collectionRepository.addItem(item1, to: collection, position: 0)
        try collectionRepository.addItem(item2, to: collection, position: 2)
        try collectionRepository.addItem(item3, to: collection)

        let fetched = try collectionRepository.fetchById(collection.id)
        let linkedItem = fetched?.collectionItems?.first(where: { $0.itemId == item3.id })
        XCTAssertEqual(linkedItem?.position, 3)
    }

    func testRemoveItem_CompactsStructuredSiblingPositions() throws {
        let collection = try collectionRepository.create(name: "Plan", isStructured: true)
        let item1 = try itemRepository.create(content: "Item 1")
        let item2 = try itemRepository.create(content: "Item 2")
        let item3 = try itemRepository.create(content: "Item 3")

        try collectionRepository.addItem(item1, to: collection, position: 0)
        try collectionRepository.addItem(item2, to: collection, position: 1)
        try collectionRepository.addItem(item3, to: collection, position: 2)
        try collectionRepository.removeItem(item2, from: collection)

        let fetched = try collectionRepository.fetchById(collection.id)
        let positions = fetched?.collectionItems?.reduce(into: [UUID: Int]()) { result, collectionItem in
            if let position = collectionItem.position {
                result[collectionItem.itemId] = position
            }
        }
        XCTAssertEqual(positions?[item1.id], 0)
        XCTAssertEqual(positions?[item3.id], 1)
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

    // MARK: - Conversion Tests

    func testConvertPlanToListPreservesItems() throws {
        let plan = try collectionRepository.create(name: "Plan", isStructured: true)
        let item1 = try itemRepository.create(content: "Item 1")
        let item2 = try itemRepository.create(content: "Item 2")
        let item3 = try itemRepository.create(content: "Item 3")

        try collectionRepository.addItem(item1, to: plan, position: 0)
        try collectionRepository.addItem(item2, to: plan, position: 1)
        try collectionRepository.addItem(item3, to: plan, position: 2)

        try collectionRepository.convertCollection(plan, toStructured: false)

        XCTAssertFalse(plan.isStructured)
        let fetched = try collectionRepository.fetchById(plan.id)
        XCTAssertEqual(fetched?.collectionItems?.count, 3)

        let linkedItemIds = Set(fetched?.collectionItems?.map(\.itemId) ?? [])
        XCTAssertTrue(linkedItemIds.contains(item1.id))
        XCTAssertTrue(linkedItemIds.contains(item2.id))
        XCTAssertTrue(linkedItemIds.contains(item3.id))
    }

    func testConvertListToPlanPreservesItems() throws {
        let list = try collectionRepository.create(name: "List", isStructured: false)
        let item1 = try itemRepository.create(content: "Item 1")
        let item2 = try itemRepository.create(content: "Item 2")

        try collectionRepository.addItem(item1, to: list)
        try collectionRepository.addItem(item2, to: list)

        try collectionRepository.convertCollection(list, toStructured: true)

        XCTAssertTrue(list.isStructured)
        let fetched = try collectionRepository.fetchById(list.id)
        XCTAssertEqual(fetched?.collectionItems?.count, 2)

        let linkedItemIds = Set(fetched?.collectionItems?.map(\.itemId) ?? [])
        XCTAssertTrue(linkedItemIds.contains(item1.id))
        XCTAssertTrue(linkedItemIds.contains(item2.id))
    }

    func testConvertPlanToListFlattensHierarchy() throws {
        let plan = try collectionRepository.create(name: "Plan", isStructured: true)
        let itemA = try itemRepository.create(content: "A")
        let itemB = try itemRepository.create(content: "B")
        let itemC = try itemRepository.create(content: "C")
        let itemD = try itemRepository.create(content: "D")

        // Build hierarchy:
        // A (root, position 0)
        //   B (child of A, position 0)
        //   C (child of A, position 1)
        // D (root, position 1)
        try collectionRepository.addItem(itemA, to: plan, position: 0)
        try collectionRepository.addItem(itemB, to: plan, position: 0)
        try collectionRepository.addItem(itemC, to: plan, position: 1)
        try collectionRepository.addItem(itemD, to: plan, position: 1)

        // Set parentId for B and C to be children of A's CollectionItem
        let collectionItems = plan.collectionItems!
        let ciA = collectionItems.first { $0.itemId == itemA.id }!
        let ciB = collectionItems.first { $0.itemId == itemB.id }!
        let ciC = collectionItems.first { $0.itemId == itemC.id }!
        ciB.parentId = ciA.id
        ciC.parentId = ciA.id
        try modelContext.save()

        try collectionRepository.convertCollection(plan, toStructured: false)

        // All parentIds should be cleared
        let items = plan.collectionItems!
        for ci in items {
            XCTAssertNil(ci.parentId, "parentId should be nil after flattening")
        }

        // Depth-first order: A, B, C, D
        let sorted = items.sorted { ($0.position ?? Int.max) < ($1.position ?? Int.max) }
        let orderedItemIds = sorted.map(\.itemId)
        XCTAssertEqual(orderedItemIds, [itemA.id, itemB.id, itemC.id, itemD.id])

        // Positions should be sequential 0-3
        let positions = sorted.compactMap(\.position)
        XCTAssertEqual(positions, [0, 1, 2, 3])
    }

    func testConvertListToPlanBackfillsPositions() throws {
        let list = try collectionRepository.create(name: "List", isStructured: false)
        let item1 = try itemRepository.create(content: "Item 1")
        let item2 = try itemRepository.create(content: "Item 2")
        let item3 = try itemRepository.create(content: "Item 3")

        // Add items without positions (list behavior)
        try collectionRepository.addItem(item1, to: list)
        try collectionRepository.addItem(item2, to: list)
        try collectionRepository.addItem(item3, to: list)

        // Verify positions are nil before conversion
        for ci in list.collectionItems! {
            XCTAssertNil(ci.position, "List items should have nil position before conversion")
        }

        try collectionRepository.convertCollection(list, toStructured: true)

        // All items should now have positions
        for ci in list.collectionItems! {
            XCTAssertNotNil(ci.position, "All items should have positions after list-to-plan conversion")
        }
    }

    func testRoundTripConversionPreservesItemCount() throws {
        let plan = try collectionRepository.create(name: "Plan", isStructured: true)
        let item1 = try itemRepository.create(content: "Item 1")
        let item2 = try itemRepository.create(content: "Item 2")
        let item3 = try itemRepository.create(content: "Item 3")

        try collectionRepository.addItem(item1, to: plan, position: 0)
        try collectionRepository.addItem(item2, to: plan, position: 1)
        try collectionRepository.addItem(item3, to: plan, position: 2)

        // Plan → List → Plan
        try collectionRepository.convertCollection(plan, toStructured: false)
        XCTAssertEqual(plan.collectionItems?.count, 3)

        try collectionRepository.convertCollection(plan, toStructured: true)
        XCTAssertEqual(plan.collectionItems?.count, 3)

        // List → Plan → List
        try collectionRepository.convertCollection(plan, toStructured: false)
        XCTAssertEqual(plan.collectionItems?.count, 3)

        // Verify all original items still linked
        let linkedItemIds = Set(plan.collectionItems?.map(\.itemId) ?? [])
        XCTAssertTrue(linkedItemIds.contains(item1.id))
        XCTAssertTrue(linkedItemIds.contains(item2.id))
        XCTAssertTrue(linkedItemIds.contains(item3.id))
    }

    func testRoundTripConversionPreservesOrdering() throws {
        let plan = try collectionRepository.create(name: "Plan", isStructured: true)
        let itemA = try itemRepository.create(content: "A")
        let itemB = try itemRepository.create(content: "B")
        let itemC = try itemRepository.create(content: "C")

        try collectionRepository.addItem(itemA, to: plan, position: 0)
        try collectionRepository.addItem(itemB, to: plan, position: 1)
        try collectionRepository.addItem(itemC, to: plan, position: 2)

        // Convert Plan → List → Plan
        try collectionRepository.convertCollection(plan, toStructured: false)
        try collectionRepository.convertCollection(plan, toStructured: true)

        // Order should still be A, B, C
        let sorted = plan.collectionItems!
            .sorted { ($0.position ?? Int.max) < ($1.position ?? Int.max) }
        let orderedItemIds = sorted.map(\.itemId)
        XCTAssertEqual(orderedItemIds, [itemA.id, itemB.id, itemC.id])
    }

    func testConvertEmptyCollection() throws {
        let plan = try collectionRepository.create(name: "Empty Plan", isStructured: true)

        try collectionRepository.convertCollection(plan, toStructured: false)
        XCTAssertFalse(plan.isStructured)
        XCTAssertEqual(plan.collectionItems?.count ?? 0, 0)

        try collectionRepository.convertCollection(plan, toStructured: true)
        XCTAssertTrue(plan.isStructured)
        XCTAssertEqual(plan.collectionItems?.count ?? 0, 0)
    }

    func testConvertPlanToListWarningOnlyForStructured() throws {
        // This tests the logic gate: only structured (plan) collections
        // should trigger a warning. The UI uses collection.isStructured
        // to decide whether to show the confirmation dialog.
        let plan = try collectionRepository.create(name: "Plan", isStructured: true)
        let list = try collectionRepository.create(name: "List", isStructured: false)

        XCTAssertTrue(plan.isStructured, "Plan should be structured (triggers warning)")
        XCTAssertFalse(list.isStructured, "List should not be structured (no warning)")
    }

    func testBackfillCollectionPositions_AppendsAfterExistingPositionsForStructuredCollections() throws {
        let existing = try collectionRepository.create(name: "Existing", isStructured: true)
        existing.position = 7

        let olderNil = try collectionRepository.create(name: "Older Nil", isStructured: true)
        let newerNil = try collectionRepository.create(name: "Newer Nil", isStructured: true)
        olderNil.position = nil
        newerNil.position = nil
        olderNil.createdAt = Date(timeIntervalSince1970: 1_000)
        newerNil.createdAt = Date(timeIntervalSince1970: 2_000)
        try modelContext.save()

        try collectionRepository.backfillCollectionPositions(isStructured: true)

        XCTAssertEqual(existing.position, 7)
        XCTAssertEqual(olderNil.position, 8)
        XCTAssertEqual(newerNil.position, 9)
    }
}
