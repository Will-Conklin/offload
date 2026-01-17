import Foundation
import SwiftData

@MainActor
final class CollectionItemRepository {
    private let modelContext: ModelContext

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
        let collectionItem = CollectionItem(
            collectionId: collectionId,
            itemId: itemId,
            position: position,
            parentId: parentId
        )
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
        collectionItem.collectionId = toCollectionId
        collectionItem.position = position
        collectionItem.parentId = nil // Reset parent when moving
        try modelContext.save()
    }
}
