// Purpose: Repository layer for data access and queries.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep CRUD logic centralized and consistent with SwiftData models.

//  Supports Tag entities linked to Item relationships.

import Foundation
import SwiftData

/// Repository for Tag CRUD operations and queries
final class TagRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    func create(tag: Tag) throws {
        modelContext.insert(tag)
        try modelContext.save()
    }

    // MARK: - Read

    func fetchAll() throws -> [Tag] {
        let descriptor = FetchDescriptor<Tag>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchById(_ id: UUID) throws -> Tag? {
        let descriptor = FetchDescriptor<Tag>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func fetchByName(_ name: String) throws -> Tag? {
        let normalizedQuery = Tag.normalizedName(name)
        guard !normalizedQuery.isEmpty else { return nil }

        // TODO: SwiftData predicates can't express case-insensitive matches; replace with indexed lookup if possible.
        let descriptor = FetchDescriptor<Tag>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        let allTags = try modelContext.fetch(descriptor)
        return allTags.first { Tag.normalizedName($0.name) == normalizedQuery }
    }

    func search(query: String) throws -> [Tag] {
        let normalizedQuery = Tag.normalizedName(query)
        guard !normalizedQuery.isEmpty else {
            return try fetchAll()
        }

        let descriptor = FetchDescriptor<Tag>(
            sortBy: [SortDescriptor(\.name)]
        )
        let allTags = try modelContext.fetch(descriptor)
        return allTags.filter { Tag.normalizedName($0.name).contains(normalizedQuery) }
    }

    /// Search tags by name (alias for search)
    func searchByName(_ query: String) throws -> [Tag] {
        try search(query: query)
    }

    /// Find or create a tag by name
    func findOrCreate(name: String, color: String? = nil) throws -> Tag {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let existing = try fetchByName(trimmedName) {
            return existing
        }

        let newTag = Tag(name: trimmedName, color: color)
        try create(tag: newTag)
        return newTag
    }

    /// Fetch or create a tag by name (alias for findOrCreate).
    func fetchOrCreate(_ name: String, color: String? = nil) throws -> Tag {
        try findOrCreate(name: name, color: color)
    }

    // MARK: - Update

    func update(tag _: Tag) throws {
        try modelContext.save()
    }

    /// Returns the number of items currently using this tag.
    func updateUsageCount(_ tag: Tag) throws -> Int {
        getTaskCount(tag: tag)
    }

    // MARK: - Delete

    func delete(tag: Tag) throws {
        if !tag.items.isEmpty {
            for item in tag.items {
                item.tags.removeAll { $0.id == tag.id }
            }
        }
        modelContext.delete(tag)
        try modelContext.save()
    }

    func fetchUnused() throws -> [Tag] {
        let tags = try fetchAll()
        return tags.filter { getTaskCount(tag: $0) == 0 }
    }

    // MARK: - Task Relationships

    /// Get combined usage count (items + collections) for this tag.
    func getTaskCount(tag: Tag) -> Int {
        usageCount(tag: tag)
    }

    /// Check if tag is used by any item or collection.
    func isTagInUse(tag: Tag) -> Bool {
        usageCount(tag: tag) > 0
    }

    private func usageCount(tag: Tag) -> Int {
        tag.items.count + tag.collections.count
    }
}
