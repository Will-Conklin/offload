//
//  TaskRepository.swift
//  Offload
//
//  Created by Claude Code on 12/31/25.
//
//  Intent: Manages tasks with completion tracking and plan organization.
//  Supports filtering by plan, category, completion status.
//

import Foundation
import SwiftData

/// Repository for Task CRUD operations and queries
final class TaskRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    func create(task: Task) throws {
        modelContext.insert(task)
        try modelContext.save()
    }

    // MARK: - Read

    /// Fetch all tasks
    func fetchAll() throws -> [Task] {
        let descriptor = FetchDescriptor<Task>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch incomplete tasks
    func fetchIncomplete() throws -> [Task] {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { $0.isDone == false },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch completed tasks
    func fetchCompleted() throws -> [Task] {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { $0.isDone == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch tasks by plan
    func fetchByPlan(_ plan: Plan) throws -> [Task] {
        let all = try fetchAll()
        return all.filter { $0.plan?.id == plan.id }
    }

    /// Fetch tasks by category
    func fetchByCategory(_ category: Category) throws -> [Task] {
        let all = try fetchAll()
        return all.filter { $0.category?.id == category.id }
    }

    /// Fetch task by ID
    func fetchById(_ id: UUID) throws -> Task? {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// Search tasks by title or detail (case-sensitive)
    func search(query: String) throws -> [Task] {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { task in
                task.title.contains(query) ||
                    (task.detail?.contains(query) ?? false)
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Update

    func update(task _: Task) throws {
        try modelContext.save()
    }

    func complete(task: Task) throws {
        task.isDone = true
        try modelContext.save()
    }

    func uncomplete(task: Task) throws {
        task.isDone = false
        try modelContext.save()
    }

    // MARK: - Delete

    func delete(task: Task) throws {
        modelContext.delete(task)
        try modelContext.save()
    }
}
