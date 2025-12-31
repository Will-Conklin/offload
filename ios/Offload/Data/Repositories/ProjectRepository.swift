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

    /// Fetch all projects (active and archived)
    func fetchAll() throws -> [Project] {
        let descriptor = FetchDescriptor<Project>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch all active (non-archived) projects
    func fetchActive() throws -> [Project] {
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate { $0.archivedAt == nil },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch all archived projects
    func fetchArchived() throws -> [Project] {
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate { $0.archivedAt != nil },
            sortBy: [SortDescriptor(\.archivedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch a project by ID
    func fetchById(_ id: UUID) throws -> Project? {
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// Search projects by name or notes (case-sensitive)
    func search(query: String) throws -> [Project] {
        let descriptor = FetchDescriptor<Project>(
            predicate: #Predicate { project in
                project.name.contains(query) ||
                (project.notes?.contains(query) ?? false)
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

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
