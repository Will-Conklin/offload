import Foundation
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
        linkedCollectionId: UUID? = nil,
        tags: [String] = [],
        isStarred: Bool = false,
        followUpDate: Date? = nil
    ) throws -> Item {
        let item = Item(
            type: type,
            content: content,
            metadata: metadata,
            linkedCollectionId: linkedCollectionId,
            tags: tags,
            isStarred: isStarred,
            followUpDate: followUpDate
        )
        modelContext.insert(item)
        try modelContext.save()
        return item
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

    func fetchByTag(_ tag: String) throws -> [Item] {
        let descriptor = FetchDescriptor<Item>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let allItems = try modelContext.fetch(descriptor)
        return allItems.filter { $0.tags.contains(tag) }
    }

    func searchByContent(_ query: String) throws -> [Item] {
        let lowercaseQuery = query.lowercased()
        let descriptor = FetchDescriptor<Item>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let allItems = try modelContext.fetch(descriptor)
        return allItems.filter { $0.content.lowercased().contains(lowercaseQuery) }
    }

    // MARK: - Update
    func update(_ item: Item) throws {
        try modelContext.save()
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

    func addTag(_ item: Item, tag: String) throws {
        if !item.tags.contains(tag) {
            item.tags.append(tag)
            try modelContext.save()
        }
    }

    func removeTag(_ item: Item, tag: String) throws {
        item.tags.removeAll { $0 == tag }
        try modelContext.save()
    }

    func updateFollowUpDate(_ item: Item, date: Date?) throws {
        item.followUpDate = date
        try modelContext.save()
    }

    // MARK: - Delete
    func delete(_ item: Item) throws {
        modelContext.delete(item)
        try modelContext.save()
    }

    func deleteMultiple(_ items: [Item]) throws {
        for item in items {
            modelContext.delete(item)
        }
        try modelContext.save()
    }
}
