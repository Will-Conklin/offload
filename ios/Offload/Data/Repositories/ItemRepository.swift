// Purpose: Repository layer for data access and queries.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Keep CRUD logic centralized and consistent with SwiftData models.

import Foundation
import OSLog
import SwiftData

@MainActor
final class ItemRepository {
    private let modelContext: ModelContext
    private let attachmentStorage: AttachmentStorage

    /// Creates a repository backed by a SwiftData context and attachment storage provider.
    /// - Parameters:
    ///   - modelContext: SwiftData context used for item persistence.
    ///   - attachmentStorage: Optional attachment storage implementation; defaults to `AttachmentStorageService`.
    init(
        modelContext: ModelContext,
        attachmentStorage: AttachmentStorage? = nil
    ) {
        self.modelContext = modelContext
        self.attachmentStorage = attachmentStorage ?? AttachmentStorageService()
    }

    // MARK: - Create

    @discardableResult
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
        let itemId = UUID()
        let preparedAttachmentPath = try prepareAttachmentPath(for: attachmentData, itemId: itemId)
        let item = Item(
            id: itemId,
            type: type,
            content: content,
            metadata: metadata,
            attachmentData: nil,
            linkedCollectionId: linkedCollectionId,
            isStarred: isStarred,
            followUpDate: followUpDate
        )
        if let preparedAttachmentPath {
            item.attachmentFilePath = preparedAttachmentPath
            item.cachedAttachmentData = attachmentData
        } else {
            item.attachmentData = attachmentData
        }
        item.tags = tags
        modelContext.insert(item)
        do {
            try modelContext.save()
            AppLogger.persistence.info("Item created - id: \(item.id, privacy: .public), type: \(type ?? "nil", privacy: .public)")
            return item
        } catch {
            if let preparedAttachmentPath {
                try? attachmentStorage.removeAttachment(at: preparedAttachmentPath)
            }
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

    /// Returns items created during the current calendar week, sorted newest-first.
    func fetchCapturedThisWeek() throws -> [Item] {
        let startOfWeek = currentWeekStart()
        let descriptor = FetchDescriptor<Item>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let all = try modelContext.fetch(descriptor)
        return all.filter { $0.createdAt >= startOfWeek }
    }

    /// Returns items completed during the current calendar week, sorted newest-first.
    func fetchCompletedThisWeek() throws -> [Item] {
        let startOfWeek = currentWeekStart()
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate<Item> { item in
                item.completedAt != nil
            },
            sortBy: [SortDescriptor(\.completedAt, order: .reverse)]
        )
        let allCompleted = try modelContext.fetch(descriptor)
        return allCompleted.filter { item in
            guard let completedAt = item.completedAt else { return false }
            return completedAt >= startOfWeek
        }
    }

    /// Returns non-completed items with a followUpDate in [startDate, endDate], sorted ascending.
    /// Limited to 50 results — sufficient for a 7-day timeline window.
    func fetchItemsWithFollowUpDate(from startDate: Date, to endDate: Date) throws -> [Item] {
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate<Item> { item in
                item.followUpDate != nil && item.completedAt == nil
            },
            sortBy: [SortDescriptor(\.followUpDate)]
        )
        let allWithFollowUp = try modelContext.fetch(descriptor)
        let filtered = allWithFollowUp.filter { item in
            guard let followUpDate = item.followUpDate else { return false }
            return followUpDate >= startDate && followUpDate <= endDate
        }
        return Array(filtered.prefix(50))
    }

    func fetchIncomplete() throws -> [Item] {
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate { $0.completedAt == nil },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchCaptureItems() throws -> [Item] {
        // Capture items: not completed, not a collection-pointer link (linkedCollectionId == nil).
        // Includes both uncategorized (type==nil) and user-typed captures.
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate { $0.linkedCollectionId == nil && $0.completedAt == nil },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchCaptureItems(limit: Int, offset: Int) throws -> [Item] {
        var descriptor = FetchDescriptor<Item>(
            predicate: #Predicate { $0.linkedCollectionId == nil && $0.completedAt == nil },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        return try modelContext.fetch(descriptor)
    }

    /// Fetches capture items filtered to a specific type, excluding completed and collection-linked items.
    /// - Parameters:
    ///   - type: The raw string value of the `ItemType` to filter by.
    ///   - limit: Maximum number of items to return.
    ///   - offset: Number of items to skip before returning results.
    func fetchCaptureItemsByType(_ type: String, limit: Int, offset: Int) throws -> [Item] {
        var descriptor = FetchDescriptor<Item>(
            predicate: #Predicate { $0.type == type && $0.completedAt == nil && $0.linkedCollectionId == nil },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        return try modelContext.fetch(descriptor)
    }

    /// Loads attachment data for an item from in-memory cache or file-backed storage.
    /// - Parameter item: Item whose attachment data should be read.
    /// - Returns: Attachment bytes when present; otherwise `nil`.
    func attachmentData(for item: Item) throws -> Data? {
        if let cachedData = item.cachedAttachmentData {
            return cachedData
        }
        guard let attachmentFilePath = item.attachmentFilePath else {
            return nil
        }

        let storedData = try attachmentStorage.loadAttachment(at: attachmentFilePath)
        item.cachedAttachmentData = storedData
        return storedData
    }

    /// Returns attachment data for UI display and suppresses read errors with logging.
    /// - Parameter item: Item whose attachment data should be loaded for rendering.
    /// - Returns: Attachment bytes when available and readable; otherwise `nil`.
    func attachmentDataForDisplay(_ item: Item) -> Data? {
        do {
            return try attachmentData(for: item)
        } catch {
            AppLogger.persistence.error("Attachment load failed - item: \(item.id, privacy: .public), error: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// Returns typed metadata decoded from an item's persisted metadata JSON string.
    /// - Parameter item: Item whose metadata should be decoded.
    /// - Returns: Typed metadata value with known fields and extension data.
    func metadata(for item: Item) -> ItemMetadata {
        item.typedMetadata
    }

    /// Persists typed metadata for an item.
    /// - Parameters:
    ///   - item: Item to update.
    ///   - metadata: Typed metadata payload to encode and store.
    func updateMetadata(_ item: Item, metadata: ItemMetadata) throws {
        item.typedMetadata = metadata
        try modelContext.save()
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

    /// Replaces an item's attachment and persists the new file reference.
    /// - Parameters:
    ///   - item: Item whose attachment should be replaced.
    ///   - attachmentData: New attachment bytes, or `nil` to remove attachment.
    func updateAttachment(_ item: Item, attachmentData: Data?) throws {
        let previousPath = item.attachmentFilePath
        let previousInlineData = item.attachmentData
        let previousCachedData = item.cachedAttachmentData
        let newAttachmentPath = try prepareAttachmentPath(for: attachmentData, itemId: item.id)

        item.attachmentData = nil
        item.attachmentFilePath = newAttachmentPath
        item.cachedAttachmentData = attachmentData

        do {
            try modelContext.save()
        } catch {
            item.attachmentFilePath = previousPath
            item.attachmentData = previousInlineData
            item.cachedAttachmentData = previousCachedData
            if let newAttachmentPath, newAttachmentPath != previousPath {
                try? attachmentStorage.removeAttachment(at: newAttachmentPath)
            }
            throw error
        }

        if let previousPath, previousPath != newAttachmentPath {
            do {
                try attachmentStorage.removeAttachment(at: previousPath)
            } catch {
                AppLogger.persistence.warning("Attachment cleanup failed after successful update - item: \(item.id, privacy: .public), path: \(previousPath, privacy: .public), error: \(error.localizedDescription, privacy: .public)")
            }
        }
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
        let attachmentPaths = items.compactMap(\.attachmentFilePath)
        for item in items {
            modelContext.delete(item)
        }
        do {
            try modelContext.save()
            for attachmentPath in attachmentPaths {
                try? attachmentStorage.removeAttachment(at: attachmentPath)
            }
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
        let attachmentPath = item.attachmentFilePath
        modelContext.delete(item)
        do {
            try modelContext.save()
            if let attachmentPath {
                try? attachmentStorage.removeAttachment(at: attachmentPath)
            }
            AppLogger.persistence.info("Item deleted - id: \(itemId, privacy: .public)")
        } catch {
            AppLogger.persistence.error("Item delete failed - id: \(itemId, privacy: .public), error: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    // MARK: - Private helpers

    private func currentWeekStart() -> Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
    }

    private func fetchCollection(by id: UUID) throws -> Collection? {
        let descriptor = FetchDescriptor<Collection>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// Stores attachment bytes and returns the persisted file path.
    /// - Parameters:
    ///   - attachmentData: Attachment data to persist.
    ///   - itemId: Item identifier used to namespace file naming.
    /// - Returns: Stored attachment file path, or `nil` when `attachmentData` is `nil`.
    private func prepareAttachmentPath(for attachmentData: Data?, itemId: UUID) throws -> String? {
        guard let attachmentData else { return nil }
        return try attachmentStorage.storeAttachment(attachmentData, for: itemId)
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
