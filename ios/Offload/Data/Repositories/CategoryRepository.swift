//
//  CategoryRepository.swift
//  Offload
//
//  Created by Claude Code on 12/31/25.
//
//  Intent: Manages categories for manual task organization.
//  Each task can have at most one category.
//

import Foundation
import SwiftData

/// Repository for Category CRUD operations and queries
final class CategoryRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    func create(category: Category) throws {
        modelContext.insert(category)
        try modelContext.save()
    }

    // MARK: - Read

    func fetchAll() throws -> [Category] {
        let descriptor = FetchDescriptor<Category>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchById(_ id: UUID) throws -> Category? {
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func fetchByName(_ name: String) throws -> Category? {
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { $0.name == name }
        )
        return try modelContext.fetch(descriptor).first
    }

    func search(query: String) throws -> [Category] {
        let descriptor = FetchDescriptor<Category>(
            predicate: #Predicate { category in
                category.name.contains(query)
            },
            sortBy: [SortDescriptor(\.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Find or create a category by name
    func findOrCreate(name: String, icon: String? = nil) throws -> Category {
        if let existing = try fetchByName(name) {
            return existing
        }

        let newCategory = Category(name: name, icon: icon)
        try create(category: newCategory)
        return newCategory
    }

    // MARK: - Update

    func update(category _: Category) throws {
        try modelContext.save()
    }

    // MARK: - Delete

    func delete(category: Category) throws {
        modelContext.delete(category)
        try modelContext.save()
    }

    // MARK: - Task Relationships

    /// Get count of tasks in this category
    func getTaskCount(category: Category) -> Int {
        category.tasks?.count ?? 0
    }

    /// Check if category is used by any tasks
    func isCategoryInUse(category: Category) -> Bool {
        getTaskCount(category: category) > 0
    }
}
