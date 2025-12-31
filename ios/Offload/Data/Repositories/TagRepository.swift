//
//  TagRepository.swift
//  Offload
//
//  Created by Claude Code on 12/31/25.
//
//  Intent: Manages tags for manual task organization.
//  Supports many-to-many relationships with tasks.
//

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
        let descriptor = FetchDescriptor<Tag>(
            predicate: #Predicate { $0.name == name }
        )
        return try modelContext.fetch(descriptor).first
    }

    func search(query: String) throws -> [Tag] {
        let descriptor = FetchDescriptor<Tag>(
            predicate: #Predicate { tag in
                tag.name.contains(query)
            },
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Find or create a tag by name
    func findOrCreate(name: String, color: String? = nil) throws -> Tag {
        if let existing = try fetchByName(name) {
            return existing
        }

        let newTag = Tag(name: name, color: color)
        try create(tag: newTag)
        return newTag
    }

    // MARK: - Update

    func update(tag: Tag) throws {
        try modelContext.save()
    }

    // MARK: - Delete

    func delete(tag: Tag) throws {
        modelContext.delete(tag)
        try modelContext.save()
    }

    // MARK: - Task Relationships

    /// Get count of tasks using this tag
    func getTaskCount(tag: Tag) -> Int {
        return tag.tasks?.count ?? 0
    }

    /// Check if tag is used by any tasks
    func isTagInUse(tag: Tag) -> Bool {
        return getTaskCount(tag: tag) > 0
    }
}
