//
//  TaskRepository.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import Foundation
import SwiftData

/// Repository for Task CRUD operations and queries
@MainActor
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

    /// Fetch all tasks in the inbox (status: .inbox)
    func fetchInbox() throws -> [Task] {
        // Fetch all and filter in memory (SwiftData enum limitations)
        let allTasks = try fetchAll()
        return allTasks.filter { $0.status == .inbox }
    }

    /// Fetch all tasks marked as next (status: .next)
    func fetchNext() throws -> [Task] {
        // Fetch all and filter in memory (SwiftData enum limitations)
        let allTasks = try fetchAll()
        return allTasks.filter { $0.status == .next }
            .sorted { $0.createdAt < $1.createdAt }
    }

    /// Fetch all tasks by status
    func fetchByStatus(_ status: TaskStatus) throws -> [Task] {
        // Fetch all and filter in memory (SwiftData enum limitations)
        let allTasks = try fetchAll()
        return allTasks.filter { $0.status == status }
    }

    /// Fetch all tasks for a specific project
    func fetchByProject(_ project: Project) throws -> [Task] {
        let projectID = project.id
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { $0.project?.id == projectID },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch all tasks with a specific tag
    func fetchByTag(_ tag: Tag) throws -> [Task] {
        // Note: SwiftData predicates have limitations with complex queries
        // This implementation fetches all tasks and filters in memory
        let allTasks = try fetchAll()
        return allTasks.filter { task in
            task.tags?.contains(where: { $0.id == tag.id }) ?? false
        }
    }

    /// Fetch all tasks in a specific category
    func fetchByCategory(_ category: Category) throws -> [Task] {
        let categoryID = category.id
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { $0.category?.id == categoryID },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch tasks due today
    func fetchDueToday() throws -> [Task] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        // Fetch all tasks and filter in memory due to predicate limitations
        let allTasks = try fetchAll()
        return allTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate >= today && dueDate < tomorrow
        }.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }

    /// Fetch overdue tasks (due date in the past and not completed)
    func fetchOverdue() throws -> [Task] {
        let now = Date()
        // Fetch all tasks and filter in memory due to predicate limitations
        let allTasks = try fetchAll()
        return allTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < now && task.completedAt == nil
        }.sorted { ($0.dueDate ?? Date.distantPast) < ($1.dueDate ?? Date.distantPast) }
    }

    /// Search tasks by title or notes (case-sensitive)
    func search(query: String) throws -> [Task] {
        let descriptor = FetchDescriptor<Task>(
            predicate: #Predicate { task in
                task.title.contains(query) ||
                (task.notes?.contains(query) ?? false)
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch all tasks (for testing and debugging)
    func fetchAll() throws -> [Task] {
        let descriptor = FetchDescriptor<Task>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Update

    func update(task: Task) throws {
        task.updatedAt = Date()
        try modelContext.save()
    }

    func complete(task: Task) throws {
        task.status = .completed
        task.completedAt = Date()
        task.updatedAt = Date()
        try modelContext.save()
    }

    // MARK: - Delete

    func delete(task: Task) throws {
        modelContext.delete(task)
        try modelContext.save()
    }

    // TODO: Implement soft delete/archive functionality
}
