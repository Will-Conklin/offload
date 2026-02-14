// Purpose: Repository layer for data access and queries.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep CRUD logic centralized and consistent with SwiftData models.

import Foundation
import OSLog
import SwiftData

@MainActor
final class ItemRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    func create(
        type: String? = nil,
        content: String,
        metadata: String = "{}",
        attachmentData: Data? = nil,
        linkedCollectionId: UUID? = nil,
        tags: [Tag] = [],
        isStarred: Bool = false,
        followUpDate: Date? = nil
    ) throws -> Item {
        AppLogger.persistence.debug("Creating item - type: \(type ?? "nil", privacy: .public)")
        let item = Item(
            type: type,
            content: content,
            metadata: metadata,
            attachmentData: attachmentData,
            linkedCollectionId: linkedCollectionId,
            tags: [],
            isStarred: isStarred,
            followUpDate: followUpDate
        )
        item.tags = tags
        modelContext.insert(item)
        do {
            try modelContext.save()
            AppLogger.persistence.info("Item created - id: \(item.id, privacy: .public), type: \(type ?? "nil", privacy: .public)")
            return item
        } catch {
            AppLogger.persistence.error("Item create failed - error: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    // MARK: - Fetch

    func fetchAll() throws -> [Item] {
        let descriptor = FetchDescriptor<Item>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchById(_ id: UUID) throws -> Item? {
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func fetchByType(_ type: String) throws -> [Item] {
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate { $0.type == type },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchStarred() throws -> [Item] {
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate { $0.isStarred == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchWithFollowUp() throws -> [Item] {
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate { $0.followUpDate != nil },
            sortBy: [SortDescriptor(\.followUpDate)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchByTag(_ tag: Tag) throws -> [Item] {
        tag.items.sorted { $0.createdAt > $1.createdAt }
    }

    func searchByContent(_ query: String) throws -> [Item] {
        let lowercaseQuery = query.lowercased()
        let descriptor = FetchDescriptor<Item>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let allItems = try modelContext.fetch(descriptor)
        return allItems.filter { $0.content.lowercased().contains(lowercaseQuery) }
    }

    func fetchUncategorized() throws -> [Item] {
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate { $0.type == nil },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchCompleted() throws -> [Item] {
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate { $0.completedAt != nil },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchIncomplete() throws -> [Item] {
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate { $0.completedAt == nil },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchCaptureItems() throws -> [Item] {
        // Capture items are uncategorized items (type=nil) that are not completed
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate { $0.type == nil && $0.completedAt == nil },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchCaptureItems(limit: Int, offset: Int) throws -> [Item] {
        var descriptor = FetchDescriptor<Item>(
            predicate: #Predicate { $0.type == nil && $0.completedAt == nil },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Update

    func update(_ item: Item) throws {
        let itemId = item.id
        AppLogger.persistence.debug("Updating item - id: \(itemId, privacy: .public)")
        do {
            try modelContext.save()
            AppLogger.persistence.info("Item updated - id: \(itemId, privacy: .public)")
        } catch {
            AppLogger.persistence.error("Item update failed - id: \(itemId, privacy: .public), error: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    func updateType(_ item: Item, type: String?) throws {
        item.type = type
        try modelContext.save()
    }

    func updateContent(_ item: Item, content: String) throws {
        item.content = content
        try modelContext.save()
    }

    func toggleStar(_ item: Item) throws {
        item.isStarred.toggle()
        try modelContext.save()
    }

    func addTag(_ item: Item, tag: Tag) throws {
        if !item.tags.contains(where: { $0.id == tag.id }) {
            item.tags.append(tag)
            try modelContext.save()
        }
    }

    func removeTag(_ item: Item, tag: Tag) throws {
        item.tags.removeAll { $0.id == tag.id }
        try modelContext.save()
    }

    func updateFollowUpDate(_ item: Item, date: Date?) throws {
        item.followUpDate = date
        try modelContext.save()
    }

    func complete(_ item: Item) throws {
        item.completedAt = Date()
        try modelContext.save()
    }

    func uncomplete(_ item: Item) throws {
        item.completedAt = nil
        try modelContext.save()
    }

    func toggleCompletion(_ item: Item) throws {
        if item.completedAt != nil {
            item.completedAt = nil
        } else {
            item.completedAt = Date()
        }
        try modelContext.save()
    }

    func markCompleted(_ item: Item) throws {
        if item.completedAt == nil {
            item.completedAt = Date()
        }
        try modelContext.save()
    }

    func moveToCollection(_ item: Item, collection: Collection, position: Int?) throws {
        _ = try upsertCollectionItem(item: item, collection: collection, position: position)
        try modelContext.save()
    }

    /// Updates the item type and collection link in a single save boundary.
    /// If save fails, all in-memory changes are rolled back.
    func moveToCollectionAtomically(_ item: Item, collection: Collection, targetType: String?, position: Int?) throws {
        try moveToCollectionAtomically(
            item,
            collection: collection,
            targetType: targetType,
            position: position,
            saveAction: { [modelContext] in try modelContext.save() }
        )
    }

    /// Testable variant that allows injecting save behavior.
    func moveToCollectionAtomically(
        _ item: Item,
        collection: Collection,
        targetType: String?,
        position: Int?,
        saveAction: () throws -> Void
    ) throws {
        guard try fetchCollection(by: collection.id) != nil else {
            throw ValidationError("Collection not found")
        }

        let originalType = item.type
        let itemId = item.id
        let collectionId = collection.id
        let existingDescriptor = FetchDescriptor<CollectionItem>(
            predicate: #Predicate {
                $0.itemId == itemId && $0.collectionId == collectionId
            }
        )
        let existingLink = try modelContext.fetch(existingDescriptor).first
        let originalExistingPosition = existingLink?.position
        let originalExistingParentId = existingLink?.parentId
        let originalExistingCollection = existingLink?.collection
        let originalExistingItem = existingLink?.item

        var insertedLink: CollectionItem?

        do {
            item.type = targetType
            if let existingLink {
                existingLink.position = position
                existingLink.parentId = nil
                existingLink.collection = collection
                existingLink.item = item
            } else {
                let collectionItem = CollectionItem(
                    collectionId: collectionId,
                    itemId: itemId,
                    position: position,
                    parentId: nil
                )
                collectionItem.collection = collection
                collectionItem.item = item
                modelContext.insert(collectionItem)
                insertedLink = collectionItem
            }

            try saveAction()
        } catch {
            modelContext.rollback()
            item.type = originalType

            if let existingLink {
                existingLink.position = originalExistingPosition
                existingLink.parentId = originalExistingParentId
                existingLink.collection = originalExistingCollection
                existingLink.item = originalExistingItem
            }

            if let insertedLink {
                modelContext.delete(insertedLink)
            }

            throw error
        }
    }

    // MARK: - Bulk Operations

    func deleteAll(_ items: [Item]) throws {
        guard !items.isEmpty else { return }
        let count = items.count
        AppLogger.persistence.debug("Deleting multiple items - count: \(count, privacy: .public)")
        for item in items {
            modelContext.delete(item)
        }
        do {
            try modelContext.save()
            AppLogger.persistence.info("Items deleted - count: \(count, privacy: .public)")
        } catch {
            AppLogger.persistence.error("Bulk delete failed - count: \(count, privacy: .public), error: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    func markAllCompleted(_ items: [Item]) throws {
        guard !items.isEmpty else { return }
        let now = Date()
        for item in items where item.completedAt == nil {
            item.completedAt = now
        }
        try modelContext.save()
    }

    // MARK: - Validation

    func validate(_ item: Item) throws -> Bool {
        !item.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Delete

    func delete(_ item: Item) throws {
        let itemId = item.id
        AppLogger.persistence.debug("Deleting item - id: \(itemId, privacy: .public)")
        modelContext.delete(item)
        do {
            try modelContext.save()
            AppLogger.persistence.info("Item deleted - id: \(itemId, privacy: .public)")
        } catch {
            AppLogger.persistence.error("Item delete failed - id: \(itemId, privacy: .public), error: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    func deleteMultiple(_ items: [Item]) throws {
        try deleteAll(items)
    }

    // MARK: - Private helpers

    private func fetchCollection(by id: UUID) throws -> Collection? {
        let descriptor = FetchDescriptor<Collection>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// Inserts a new collection link or updates an existing one for the same item/collection pair.
    private func upsertCollectionItem(item: Item, collection: Collection, position: Int?) throws -> CollectionItem {
        let itemId = item.id
        let collectionId = collection.id
        let descriptor = FetchDescriptor<CollectionItem>(
            predicate: #Predicate {
                $0.itemId == itemId && $0.collectionId == collectionId
            }
        )

        if let existing = try modelContext.fetch(descriptor).first {
            existing.position = position
            existing.parentId = nil
            existing.collection = collection
            existing.item = item
            return existing
        }

        let collectionItem = CollectionItem(
            collectionId: collectionId,
            itemId: itemId,
            position: position,
            parentId: nil
        )
        collectionItem.collection = collection
        collectionItem.item = item
        modelContext.insert(collectionItem)
        return collectionItem
    }
}
