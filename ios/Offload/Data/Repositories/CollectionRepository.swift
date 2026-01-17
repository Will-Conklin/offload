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
