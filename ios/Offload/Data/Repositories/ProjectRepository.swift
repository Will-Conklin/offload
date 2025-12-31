//
//  ProjectRepository.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import Foundation
import SwiftData

/// Repository for Project CRUD operations and queries
@MainActor
final class ProjectRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    func create(project: Project) throws {
        modelContext.insert(project)
        try modelContext.save()
    }

    // MARK: - Read

    // TODO: Implement fetchAll() -> [Project]
    // TODO: Implement fetchActive() -> [Project]
    // TODO: Implement fetchArchived() -> [Project]
    // TODO: Implement fetchById(_ id: UUID) -> Project?

    // MARK: - Update

    func update(project: Project) throws {
        project.updatedAt = Date()
        try modelContext.save()
    }

    // MARK: - Delete

    func delete(project: Project) throws {
        modelContext.delete(project)
        try modelContext.save()
    }

    func archive(project: Project) throws {
        project.archivedAt = Date()
        project.updatedAt = Date()
        try modelContext.save()
    }
}
