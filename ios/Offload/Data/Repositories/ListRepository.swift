//
//  ListRepository.swift
//  Offload
//
//  Created by Claude Code on 12/31/25.
//
//  Intent: Manages lists and list items for simple checklists.
//  Handles shopping lists, packing lists, and reference lists.
//

import Foundation
import SwiftData

/// Repository for ListEntity and ListItem CRUD operations and queries
final class ListRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - ListEntity Operations

    func createList(list: ListEntity) throws {
        modelContext.insert(list)
        try modelContext.save()
    }

    func fetchAllLists() throws -> [ListEntity] {
        let descriptor = FetchDescriptor<ListEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchListById(_ id: UUID) throws -> ListEntity? {
        let descriptor = FetchDescriptor<ListEntity>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func fetchListsByKind(_ kind: ListKind) throws -> [ListEntity] {
        let all = try fetchAllLists()
        return all.filter { $0.listKind == kind }
    }

    func updateList(list _: ListEntity) throws {
        try modelContext.save()
    }

    func deleteList(list: ListEntity) throws {
        modelContext.delete(list)
        try modelContext.save()
    }

    // MARK: - ListItem Operations

    func createItem(item: ListItem) throws {
        modelContext.insert(item)
        try modelContext.save()
    }

    func fetchItemsByList(_ listId: UUID) throws -> [ListItem] {
        let descriptor = FetchDescriptor<ListItem>(
            predicate: #Predicate { item in
                item.list?.id == listId
            }
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchItemById(_ id: UUID) throws -> ListItem? {
        let descriptor = FetchDescriptor<ListItem>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func toggleItemChecked(item: ListItem) throws {
        item.isChecked.toggle()
        try modelContext.save()
    }

    func updateItem(item _: ListItem) throws {
        try modelContext.save()
    }

    func deleteItem(item: ListItem) throws {
        modelContext.delete(item)
        try modelContext.save()
    }

    // MARK: - Bulk Operations

    /// Get completion stats for a list
    func getListStats(list: ListEntity) throws -> (total: Int, checked: Int) {
        guard let items = list.items else {
            return (0, 0)
        }
        let total = items.count
        let checked = items.filter(\.isChecked).count
        return (total, checked)
    }

    /// Clear all checked items from a list
    func clearCheckedItems(list: ListEntity) throws {
        guard let items = list.items else { return }

        let checkedItems = items.filter(\.isChecked)
        for item in checkedItems {
            modelContext.delete(item)
        }
        try modelContext.save()
    }
}
