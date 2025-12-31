//
//  PlacementRepository.swift
//  Offload
//
//  Created by Claude Code on 12/31/25.
//
//  Intent: Manages placement audit trail linking suggestions to destinations.
//  Tracks where accepted AI suggestions ended up in the user's organization structure.
//

import Foundation
import SwiftData

/// Repository for Placement CRUD operations and queries
final class PlacementRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    func create(placement: Placement) throws {
        modelContext.insert(placement)
        try modelContext.save()
    }

    // MARK: - Read

    func fetchAll() throws -> [Placement] {
        let descriptor = FetchDescriptor<Placement>(
            sortBy: [SortDescriptor(\.placedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchById(_ id: UUID) throws -> Placement? {
        let descriptor = FetchDescriptor<Placement>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// Fetch placements that came from a specific suggestion
    func fetchBySourceSuggestion(_ suggestionId: UUID) throws -> [Placement] {
        let descriptor = FetchDescriptor<Placement>(
            predicate: #Predicate { placement in
                placement.sourceSuggestionId == suggestionId
            },
            sortBy: [SortDescriptor(\.placedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch placements by target type (plan, task, list, etc.)
    func fetchByTargetType(_ type: PlacementTargetType) throws -> [Placement] {
        let all = try fetchAll()
        return all.filter { $0.target == type }
    }

    /// Fetch placements pointing to a specific target entity
    func fetchByTarget(type: PlacementTargetType, id: UUID) throws -> [Placement] {
        let descriptor = FetchDescriptor<Placement>(
            predicate: #Predicate { placement in
                placement.targetId == id
            }
        )
        let all = try modelContext.fetch(descriptor)
        return all.filter { $0.target == type }
    }

    // MARK: - Update

    func update(placement: Placement) throws {
        try modelContext.save()
    }

    // MARK: - Delete

    func delete(placement: Placement) throws {
        modelContext.delete(placement)
        try modelContext.save()
    }
}
