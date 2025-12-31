//
//  ListRepositoryTests.swift
//  OffloadTests
//
//  Created by Claude Code on 12/31/25.
//

import XCTest
import SwiftData
@testable import offload

@MainActor
final class ListRepositoryTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var repository: ListRepository!

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
        repository = ListRepository(modelContext: modelContext)
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
        repository = nil
    }

    func testCreateList() throws {
        let list = ListEntity(title: "Groceries", kind: .shopping)

        try repository.createList(list: list)

        let fetched = try repository.fetchAllLists()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "Groceries")
        XCTAssertEqual(fetched.first?.listKind, .shopping)
    }

    func testFetchListsByKind() throws {
        let list1 = ListEntity(title: "Groceries", kind: .shopping)
        let list2 = ListEntity(title: "Vacation packing", kind: .packing)
        let list3 = ListEntity(title: "Weekend shopping", kind: .shopping)

        try repository.createList(list: list1)
        try repository.createList(list: list2)
        try repository.createList(list: list3)

        let shopping = try repository.fetchListsByKind(.shopping)
        XCTAssertEqual(shopping.count, 2)

        let packing = try repository.fetchListsByKind(.packing)
        XCTAssertEqual(packing.count, 1)
    }

    func testCreateItem() throws {
        let list = ListEntity(title: "Groceries", kind: .shopping)
        try repository.createList(list: list)

        let item = ListItem(text: "Milk", list: list)
        try repository.createItem(item: item)

        let items = try repository.fetchItemsByList(list.id)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.text, "Milk")
        XCTAssertFalse(items.first?.isChecked ?? true)
    }

    func testToggleItemChecked() throws {
        let list = ListEntity(title: "Groceries", kind: .shopping)
        try repository.createList(list: list)

        let item = ListItem(text: "Milk", list: list)
        try repository.createItem(item: item)

        XCTAssertFalse(item.isChecked)

        try repository.toggleItemChecked(item: item)
        XCTAssertTrue(item.isChecked)

        try repository.toggleItemChecked(item: item)
        XCTAssertFalse(item.isChecked)
    }

    func testGetListStats() throws {
        let list = ListEntity(title: "Groceries", kind: .shopping)
        try repository.createList(list: list)

        let item1 = ListItem(text: "Milk", isChecked: false, list: list)
        let item2 = ListItem(text: "Bread", isChecked: true, list: list)
        let item3 = ListItem(text: "Eggs", isChecked: true, list: list)

        try repository.createItem(item: item1)
        try repository.createItem(item: item2)
        try repository.createItem(item: item3)

        let stats = try repository.getListStats(list: list)
        XCTAssertEqual(stats.total, 3)
        XCTAssertEqual(stats.checked, 2)
    }

    func testClearCheckedItems() throws {
        let list = ListEntity(title: "Groceries", kind: .shopping)
        try repository.createList(list: list)

        let item1 = ListItem(text: "Milk", isChecked: false, list: list)
        let item2 = ListItem(text: "Bread", isChecked: true, list: list)
        let item3 = ListItem(text: "Eggs", isChecked: true, list: list)

        try repository.createItem(item: item1)
        try repository.createItem(item: item2)
        try repository.createItem(item: item3)

        XCTAssertEqual(try repository.fetchItemsByList(list.id).count, 3)

        try repository.clearCheckedItems(list: list)

        let remaining = try repository.fetchItemsByList(list.id)
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining.first?.text, "Milk")
    }

    func testDeleteListCascadesToItems() throws {
        let list = ListEntity(title: "Groceries", kind: .shopping)
        try repository.createList(list: list)

        let item1 = ListItem(text: "Milk", list: list)
        let item2 = ListItem(text: "Bread", list: list)

        try repository.createItem(item: item1)
        try repository.createItem(item: item2)

        try repository.deleteList(list: list)

        let lists = try repository.fetchAllLists()
        XCTAssertEqual(lists.count, 0)

        // Items should be deleted due to cascade
        let items = try repository.fetchItemsByList(list.id)
        XCTAssertEqual(items.count, 0)
    }

    func testUpdateItem() throws {
        let list = ListEntity(title: "Groceries", kind: .shopping)
        try repository.createList(list: list)

        let item = ListItem(text: "Milk", list: list)
        try repository.createItem(item: item)

        item.text = "Whole Milk"
        try repository.updateItem(item: item)

        let fetched = try repository.fetchItemById(item.id)
        XCTAssertEqual(fetched?.text, "Whole Milk")
    }
}
