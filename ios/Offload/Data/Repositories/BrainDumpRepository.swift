//
//  BrainDumpRepository.swift
//  Offload
//
//  Created by Claude Code on 12/31/25.
//

import Foundation
import SwiftData

/// Repository for BrainDumpEntry CRUD operations and queries
final class BrainDumpRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    func create(entry: BrainDumpEntry) throws {
        modelContext.insert(entry)
        try modelContext.save()
    }

    // MARK: - Read

    /// Fetch all brain dump entries
    func fetchAll() throws -> [BrainDumpEntry] {
        let descriptor = FetchDescriptor<BrainDumpEntry>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch entries in 'raw' state (inbox)
    func fetchInbox() throws -> [BrainDumpEntry] {
        let all = try fetchAll()
        return all.filter { $0.currentLifecycleState == .raw }
    }

    /// Fetch entries by lifecycle state
    func fetchByState(_ state: LifecycleState) throws -> [BrainDumpEntry] {
        let all = try fetchAll()
        return all.filter { $0.currentLifecycleState == state }
    }

    /// Fetch entries that have been handed off to AI
    func fetchHandedOff() throws -> [BrainDumpEntry] {
        let all = try fetchAll()
        return all.filter { $0.currentLifecycleState == .handedOff }
    }

    /// Fetch entries ready for placement
    func fetchReady() throws -> [BrainDumpEntry] {
        let all = try fetchAll()
        return all.filter { $0.currentLifecycleState == .ready }
    }

    /// Fetch entry by ID
    func fetchById(_ id: UUID) throws -> BrainDumpEntry? {
        let descriptor = FetchDescriptor<BrainDumpEntry>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// Search entries by raw text (case-sensitive)
    func search(query: String) throws -> [BrainDumpEntry] {
        let descriptor = FetchDescriptor<BrainDumpEntry>(
            predicate: #Predicate { entry in
                entry.rawText.contains(query)
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Update

    func update(entry: BrainDumpEntry) throws {
        try modelContext.save()
    }

    func updateLifecycleState(entry: BrainDumpEntry, to state: LifecycleState) throws {
        entry.currentLifecycleState = state
        try modelContext.save()
    }

    func setAcceptedSuggestion(entry: BrainDumpEntry, suggestionId: UUID) throws {
        entry.acceptedSuggestionId = suggestionId
        entry.currentLifecycleState = .ready
        try modelContext.save()
    }

    // MARK: - Delete

    func delete(entry: BrainDumpEntry) throws {
        modelContext.delete(entry)
        try modelContext.save()
    }

    func archive(entry: BrainDumpEntry) throws {
        entry.currentLifecycleState = .archived
        try modelContext.save()
    }
}
