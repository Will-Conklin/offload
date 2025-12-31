//
//  PlanRepository.swift
//  Offload
//
//  Created by Claude Code on 12/31/25.
//
//  Intent: Manages plans (task containers) for organizing work.
//  Simple CRUD with archive support - no complex hierarchy.
//

import Foundation
import SwiftData

/// Repository for Plan CRUD operations and queries
final class PlanRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    func create(plan: Plan) throws {
        modelContext.insert(plan)
        try modelContext.save()
    }

    // MARK: - Read

    /// Fetch all plans (active and archived)
    func fetchAll() throws -> [Plan] {
        let descriptor = FetchDescriptor<Plan>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch all active (non-archived) plans
    func fetchActive() throws -> [Plan] {
        let descriptor = FetchDescriptor<Plan>(
            predicate: #Predicate { $0.isArchived == false },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch all archived plans
    func fetchArchived() throws -> [Plan] {
        let descriptor = FetchDescriptor<Plan>(
            predicate: #Predicate { $0.isArchived == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch a plan by ID
    func fetchById(_ id: UUID) throws -> Plan? {
        let descriptor = FetchDescriptor<Plan>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// Search plans by title or detail (case-sensitive)
    func search(query: String) throws -> [Plan] {
        let descriptor = FetchDescriptor<Plan>(
            predicate: #Predicate { plan in
                plan.title.contains(query) ||
                    (plan.detail?.contains(query) ?? false)
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Update

    func update(plan _: Plan) throws {
        try modelContext.save()
    }

    // MARK: - Delete

    func delete(plan: Plan) throws {
        modelContext.delete(plan)
        try modelContext.save()
    }

    func archive(plan: Plan) throws {
        plan.isArchived = true
        try modelContext.save()
    }

    func unarchive(plan: Plan) throws {
        plan.isArchived = false
        try modelContext.save()
    }
}
