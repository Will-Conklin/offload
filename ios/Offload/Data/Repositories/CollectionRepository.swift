// Purpose: Repository layer for data access and queries.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep CRUD logic centralized and consistent with SwiftData models.

import Foundation
import OSLog
import SwiftData

@MainActor
final class CollectionRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    func create(
        name: String,
        isStructured: Bool = false
    ) throws -> Collection {
        AppLogger.persistence.debug("Creating collection - name: \(name, privacy: .public), isStructured: \(isStructured, privacy: .public)")
        let collection = Collection(
            name: name,
            isStructured: isStructured
        )
        modelContext.insert(collection)
        do {
            try modelContext.save()
            AppLogger.persistence.info("Collection created - id: \(collection.id, privacy: .public)")
            return collection
        } catch {
            AppLogger.persistence.error("Collection create failed - error: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    // MARK: - Fetch

    func fetchAll() throws -> [Collection] {
        let descriptor = FetchDescriptor<Collection>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchWithItems() throws -> [Collection] {
        let collections = try fetchAll()
        for collection in collections {
            _ = collection.collectionItems?.count
        }
        return collections
    }

    func fetchById(_ id: UUID) throws -> Collection? {
        let descriptor = FetchDescriptor<Collection>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func fetchStructured() throws -> [Collection] {
        let descriptor = FetchDescriptor<Collection>(
            predicate: #Predicate { $0.isStructured == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchUnstructured() throws -> [Collection] {
        let descriptor = FetchDescriptor<Collection>(
            predicate: #Predicate { $0.isStructured == false },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchPage(isStructured: Bool, limit: Int, offset: Int) throws -> [Collection] {
        var descriptor = FetchDescriptor<Collection>(
            predicate: #Predicate { $0.isStructured == isStructured },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        return try modelContext.fetch(descriptor)
    }

    func searchByName(_ query: String) throws -> [Collection] {
        let lowercaseQuery = query.lowercased()
        let descriptor = FetchDescriptor<Collection>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let allCollections = try modelContext.fetch(descriptor)
        return allCollections.filter { $0.name.lowercased().contains(lowercaseQuery) }
    }

    // MARK: - Update

    func update(_ collection: Collection) throws {
        let collectionId = collection.id
        AppLogger.persistence.debug("Updating collection - id: \(collectionId, privacy: .public)")
        do {
            try modelContext.save()
            AppLogger.persistence.info("Collection updated - id: \(collectionId, privacy: .public)")
        } catch {
            AppLogger.persistence.error("Collection update failed - id: \(collectionId, privacy: .public), error: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    func updateName(_ collection: Collection, name: String) throws {
        collection.name = name
        try modelContext.save()
    }

    func updateIsStructured(_ collection: Collection, isStructured: Bool) throws {
        collection.isStructured = isStructured
        try modelContext.save()
    }

    func addItem(_ item: Item, to collection: Collection, position: Int? = nil) throws {
        let resolvedPosition: Int? = {
            if let position {
                return position
            }
            return collection.isStructured ? (collection.collectionItems?.count ?? 0) : nil
        }()
        let collectionItem = CollectionItem(
            collectionId: collection.id,
            itemId: item.id,
            position: resolvedPosition,
            parentId: nil
        )
        collectionItem.collection = collection
        collectionItem.item = item
        modelContext.insert(collectionItem)
        try modelContext.save()
    }

    func removeItem(_ item: Item, from collection: Collection) throws {
        guard let collectionItems = collection.collectionItems else { return }
        for collectionItem in collectionItems where collectionItem.itemId == item.id {
            modelContext.delete(collectionItem)
        }
        try modelContext.save()
    }

    func reorderItems(_ items: [Item], in collection: Collection) throws {
        let collectionItems = collection.collectionItems ?? []
        let orderedItemIds = items.map(\.id)
        for (index, itemId) in orderedItemIds.enumerated() {
            if let collectionItem = collectionItems.first(where: { $0.itemId == itemId }) {
                collectionItem.position = index
            }
        }
        try modelContext.save()
    }

    // MARK: - Star

    func toggleStar(_ collection: Collection) throws {
        collection.isStarred.toggle()
        try modelContext.save()
    }

    // MARK: - Tags

    func addTag(_ collection: Collection, tag: Tag) throws {
        if !collection.tags.contains(where: { $0.id == tag.id }) {
            collection.tags.append(tag)
            try modelContext.save()
        }
    }

    func removeTag(_ collection: Collection, tag: Tag) throws {
        collection.tags.removeAll { $0.id == tag.id }
        try modelContext.save()
    }

    // MARK: - Delete

    func delete(_ collection: Collection) throws {
        let collectionId = collection.id
        AppLogger.persistence.debug("Deleting collection - id: \(collectionId, privacy: .public)")
        modelContext.delete(collection)
        do {
            try modelContext.save()
            AppLogger.persistence.info("Collection deleted - id: \(collectionId, privacy: .public)")
        } catch {
            AppLogger.persistence.error("Collection delete failed - id: \(collectionId, privacy: .public), error: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    // MARK: - Helper methods

    func getItemCount(_ collection: Collection) -> Int {
        collection.collectionItems?.count ?? 0
    }

    func getItems(_ collection: Collection) throws -> [Item] {
        guard let collectionItems = collection.collectionItems else { return [] }
        return collectionItems.compactMap(\.item)
    }

    func backfillPositions(_ collection: Collection) throws {
        AppLogger.general.info("Backfilling positions for collection \(collection.name, privacy: .public)")

        guard let collectionItems = collection.collectionItems else {
            AppLogger.general.info("No items to backfill")
            return
        }

        var itemsNeedingPosition: [CollectionItem] = []
        for collectionItem in collectionItems {
            if collectionItem.position == nil {
                itemsNeedingPosition.append(collectionItem)
            }
        }

        if itemsNeedingPosition.isEmpty {
            AppLogger.general.info("All items already have positions")
            return
        }

        AppLogger.general.info("Found \(itemsNeedingPosition.count, privacy: .public) items needing positions")

        // Sort items needing position by creation date to maintain chronological order
        let sortedItems = itemsNeedingPosition.sorted { item1, item2 in
            guard let date1 = item1.item?.createdAt,
                  let date2 = item2.item?.createdAt
            else {
                return false
            }
            return date1 < date2
        }

        // Get the highest existing position, or start at 0
        let maxPosition = collectionItems.compactMap(\.position).max() ?? -1
        var nextPosition = maxPosition + 1

        // Assign positions
        for item in sortedItems {
            item.position = nextPosition
            nextPosition += 1
        }

        try modelContext.save()
        AppLogger.general.info("Backfilled \(sortedItems.count, privacy: .public) positions")
    }
}
