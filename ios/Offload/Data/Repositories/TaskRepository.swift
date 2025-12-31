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

    // TODO: Implement fetchInbox() -> [Task]
    // TODO: Implement fetchNext() -> [Task]
    // TODO: Implement fetchByProject(_ project: Project) -> [Task]
    // TODO: Implement fetchByTag(_ tag: Tag) -> [Task]
    // TODO: Implement fetchByCategory(_ category: Category) -> [Task]
    // TODO: Implement fetchDueToday() -> [Task]
    // TODO: Implement fetchOverdue() -> [Task]
    // TODO: Implement search(query: String) -> [Task]

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
