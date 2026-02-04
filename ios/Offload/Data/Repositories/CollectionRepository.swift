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
            predicate: #Predicate { $0.isStructured == true }
        )
        let collections = try modelContext.fetch(descriptor)
        // Sort by position (if set), then by createdAt
        return collections.sorted { c1, c2 in
            if let p1 = c1.position, let p2 = c2.position {
                return p1 < p2
            } else if c1.position != nil {
                return true  // c1 has position, c2 doesn't
            } else if c2.position != nil {
                return false // c2 has position, c1 doesn't
            } else {
                return c1.createdAt > c2.createdAt // Both nil, use createdAt descending
            }
        }
    }

    func fetchUnstructured() throws -> [Collection] {
        let descriptor = FetchDescriptor<Collection>(
            predicate: #Predicate { $0.isStructured == false }
        )
        let collections = try modelContext.fetch(descriptor)
        // Sort by position (if set), then by createdAt
        return collections.sorted { c1, c2 in
            if let p1 = c1.position, let p2 = c2.position {
                return p1 < p2
            } else if c1.position != nil {
                return true  // c1 has position, c2 doesn't
            } else if c2.position != nil {
                return false // c2 has position, c1 doesn't
            } else {
                return c1.createdAt > c2.createdAt // Both nil, use createdAt descending
            }
        }
    }

    func fetchPage(isStructured: Bool, limit: Int, offset: Int) throws -> [Collection] {
        // Fetch all, sort, then apply pagination
        let descriptor = FetchDescriptor<Collection>(
            predicate: #Predicate { $0.isStructured == isStructured }
        )
        let collections = try modelContext.fetch(descriptor)
        let sorted = collections.sorted { c1, c2 in
            if let p1 = c1.position, let p2 = c2.position {
                return p1 < p2
            } else if c1.position != nil {
                return true
            } else if c2.position != nil {
                return false
            } else {
                return c1.createdAt > c2.createdAt
            }
        }
        let startIndex = min(offset, sorted.count)
        let endIndex = min(offset + limit, sorted.count)
        return Array(sorted[startIndex..<endIndex])
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

    func convertCollection(_ collection: Collection, toStructured: Bool) throws {
        AppLogger.general.info("Converting collection \(collection.name) to \(toStructured ? "structured (plan)" : "unstructured (list)", privacy: .public)")

        // If converting from plan to list, flatten hierarchy
        if collection.isStructured && !toStructured {
            AppLogger.general.info("Flattening hierarchy for plan-to-list conversion", privacy: .public)

            // Get all collection items
            guard let collectionItems = collection.collectionItems else {
                AppLogger.general.warning("No collection items found during conversion", privacy: .public)
                collection.isStructured = toStructured
                try modelContext.save()
                return
            }

            // Clear parentId from all items and ensure position is set
            for (index, collectionItem) in collectionItems.enumerated() {
                collectionItem.parentId = nil
                // Backfill position if not set
                if collectionItem.position == nil {
                    collectionItem.position = index
                }
            }
        }

        // If converting from list to plan, ensure all items have position set
        if !collection.isStructured && toStructured {
            AppLogger.general.info("Ensuring positions for list-to-plan conversion", privacy: .public)

            guard let collectionItems = collection.collectionItems else {
                collection.isStructured = toStructured
                try modelContext.save()
                return
            }

            // Backfill positions for items that don't have them
            for (index, collectionItem) in collectionItems.enumerated() {
                if collectionItem.position == nil {
                    collectionItem.position = index
                }
            }
        }

        // Update the isStructured flag
        collection.isStructured = toStructured
        try modelContext.save()

        AppLogger.general.info("Collection converted successfully", privacy: .public)
    }

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

    // MARK: - Reordering

    func reorderCollections(_ collections: [Collection]) throws {
        AppLogger.persistence.debug("Reordering \(collections.count, privacy: .public) collections")
        for (index, collection) in collections.enumerated() {
            collection.position = index
        }
        do {
            try modelContext.save()
            AppLogger.persistence.info("Collections reordered successfully")
        } catch {
            AppLogger.persistence.error("Collections reorder failed: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    func backfillCollectionPositions(isStructured: Bool) throws {
        AppLogger.general.info("Backfilling collection positions for \(isStructured ? "plans" : "lists", privacy: .public)")

        let collections = try isStructured ? fetchStructured() : fetchUnstructured()
        let collectionsNeedingPosition = collections.filter { $0.position == nil }

        guard !collectionsNeedingPosition.isEmpty else {
            AppLogger.general.info("All collections already have positions")
            return
        }

        AppLogger.general.info("Found \(collectionsNeedingPosition.count, privacy: .public) collections needing positions")

        // Sort by creation date and assign positions
        let sorted = collectionsNeedingPosition.sorted { $0.createdAt < $1.createdAt }
        for (index, collection) in sorted.enumerated() {
            collection.position = index
        }

        try modelContext.save()
        AppLogger.general.info("Collection positions backfilled successfully")
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
