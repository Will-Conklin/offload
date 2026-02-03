// Purpose: Repository layer for data access and queries.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep CRUD logic centralized and consistent with SwiftData models.

import Foundation
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
        let collection = Collection(
            name: name,
            isStructured: isStructured
        )
        modelContext.insert(collection)
        try modelContext.save()
        return collection
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
        try modelContext.save()
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
        let orderedItemIds = items.map { $0.id }
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
        modelContext.delete(collection)
        try modelContext.save()
    }

    // MARK: - Helper methods
    func getItemCount(_ collection: Collection) -> Int {
        return collection.collectionItems?.count ?? 0
    }

    func getItems(_ collection: Collection) throws -> [Item] {
        guard let collectionItems = collection.collectionItems else { return [] }
        return collectionItems.compactMap { $0.item }
    }
}
