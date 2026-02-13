// Purpose: Repository layer for data access and queries.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep CRUD logic centralized and consistent with SwiftData models.

import Foundation
import OSLog
import SwiftData

@MainActor
final class CollectionItemRepository {
    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    func addItemToCollection(
        itemId: UUID,
        collectionId: UUID,
        position: Int? = nil,
        parentId: UUID? = nil
    ) throws -> CollectionItem {
        let collection = try fetchCollection(collectionId)
        guard let collection else {
            AppLogger.persistence.error("Failed to add item to collection - collection not found: \(collectionId, privacy: .public)")
            throw ValidationError("Collection not found")
        }

        let item = try fetchItem(itemId)
        guard let item else {
            AppLogger.persistence.error("Failed to add item to collection - item not found: \(itemId, privacy: .public)")
            throw ValidationError("Item not found")
        }

        let collectionItem = CollectionItem(
            collectionId: collectionId,
            itemId: itemId,
            position: position,
            parentId: parentId
        )
        collectionItem.collection = collection
        collectionItem.item = item
        modelContext.insert(collectionItem)
        try modelContext.save()
        return collectionItem
    }

    // MARK: - Fetch

    func fetchByCollection(_ collectionId: UUID) throws -> [CollectionItem] {
        let descriptor = FetchDescriptor<CollectionItem>(
            predicate: #Predicate { $0.collectionId == collectionId },
            sortBy: [SortDescriptor(\.position)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchPage(
        collectionId: UUID,
        isStructured: Bool,
        limit: Int,
        offset: Int
    ) throws -> [CollectionItem] {
        var descriptor = if isStructured {
            FetchDescriptor<CollectionItem>(
                predicate: #Predicate { $0.collectionId == collectionId },
                sortBy: [SortDescriptor(\.position)]
            )
        } else {
            FetchDescriptor<CollectionItem>(
                predicate: #Predicate { $0.collectionId == collectionId },
                sortBy: [SortDescriptor(\CollectionItem.item?.createdAt, order: .forward)]
            )
        }
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        return try modelContext.fetch(descriptor)
    }

    func fetchByItem(_ itemId: UUID) throws -> [CollectionItem] {
        let descriptor = FetchDescriptor<CollectionItem>(
            predicate: #Predicate { $0.itemId == itemId }
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchRootItems(_ collectionId: UUID) throws -> [CollectionItem] {
        let descriptor = FetchDescriptor<CollectionItem>(
            predicate: #Predicate {
                $0.collectionId == collectionId && $0.parentId == nil
            },
            sortBy: [SortDescriptor(\.position)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchChildren(_ parentId: UUID) throws -> [CollectionItem] {
        let descriptor = FetchDescriptor<CollectionItem>(
            predicate: #Predicate { $0.parentId == parentId },
            sortBy: [SortDescriptor(\.position)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchById(_ id: UUID) throws -> CollectionItem? {
        let descriptor = FetchDescriptor<CollectionItem>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    // MARK: - Update

    func updatePosition(_ collectionItem: CollectionItem, position: Int) throws {
        collectionItem.position = position
        try modelContext.save()
    }

    func updateParent(_ collectionItem: CollectionItem, parentId: UUID?) throws {
        collectionItem.parentId = parentId
        try modelContext.save()
    }

    func reorderItems(_ collectionId: UUID, itemIds: [UUID]) throws {
        let items = try fetchByCollection(collectionId)
        for (index, itemId) in itemIds.enumerated() {
            if let item = items.first(where: { $0.itemId == itemId }) {
                item.position = index
            }
        }
        try modelContext.save()
    }

    func reorder(for collection: Collection) throws {
        let orderedItems = collection.sortedItems
        for (index, collectionItem) in orderedItems.enumerated() {
            collectionItem.position = index
        }
        try modelContext.save()
    }

    // MARK: - Delete

    func removeItemFromCollection(_ collectionItem: CollectionItem) throws {
        modelContext.delete(collectionItem)
        try modelContext.save()
    }

    func removeItemFromAllCollections(_ itemId: UUID) throws {
        let collectionItems = try fetchByItem(itemId)
        for collectionItem in collectionItems {
            modelContext.delete(collectionItem)
        }
        try modelContext.save()
    }

    // MARK: - Helper methods

    func isItemInCollection(itemId: UUID, collectionId: UUID) throws -> Bool {
        let descriptor = FetchDescriptor<CollectionItem>(
            predicate: #Predicate {
                $0.itemId == itemId && $0.collectionId == collectionId
            }
        )
        let results = try modelContext.fetch(descriptor)
        return !results.isEmpty
    }

    func moveItemToCollection(
        collectionItem: CollectionItem,
        toCollectionId: UUID,
        position: Int? = nil
    ) throws {
        let collection = try fetchCollection(toCollectionId)
        guard let collection else {
            AppLogger.persistence.error("Failed to move item - collection not found: \(toCollectionId, privacy: .public)")
            throw ValidationError("Collection not found")
        }

        collectionItem.collectionId = toCollectionId
        collectionItem.collection = collection
        collectionItem.position = position
        collectionItem.parentId = nil // Reset parent when moving
        try modelContext.save()
    }

    // MARK: - Private helpers

    private func fetchCollection(_ id: UUID) throws -> Collection? {
        let descriptor = FetchDescriptor<Collection>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    private func fetchItem(_ id: UUID) throws -> Item? {
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }
}
