//
//  CaptureRepository.swift
//  Offload
//
//  Created by Claude Code on 12/31/25.
//
//  Intent: Manages thought capture entries throughout their lifecycle.
//  Supports inbox queries (raw entries), state transitions, and AI hand-off tracking.
//

import Foundation
import SwiftData

/// Repository for CaptureEntry CRUD operations and queries
final class CaptureRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    func create(entry: CaptureEntry) throws {
        modelContext.insert(entry)
        try modelContext.save()
    }

    // MARK: - Read

    /// Fetch all capture entries
    func fetchAll() throws -> [CaptureEntry] {
        let descriptor = FetchDescriptor<CaptureEntry>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch entries in 'raw' state (inbox)
    func fetchInbox() throws -> [CaptureEntry] {
        let predicate = #Predicate<CaptureEntry> { $0.currentLifecycleState == .raw }
        let descriptor = FetchDescriptor<CaptureEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch entries by lifecycle state
    func fetchByState(_ state: LifecycleState) throws -> [CaptureEntry] {
        let predicate = #Predicate<CaptureEntry> { $0.currentLifecycleState == state }
        let descriptor = FetchDescriptor<CaptureEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch entries that have been handed off to AI
    func fetchHandedOff() throws -> [CaptureEntry] {
        let predicate = #Predicate<CaptureEntry> { $0.currentLifecycleState == .handedOff }
        let descriptor = FetchDescriptor<CaptureEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch entries ready for placement
    func fetchReady() throws -> [CaptureEntry] {
        let predicate = #Predicate<CaptureEntry> { $0.currentLifecycleState == .ready }
        let descriptor = FetchDescriptor<CaptureEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch entry by ID
    func fetchById(_ id: UUID) throws -> CaptureEntry? {
        let descriptor = FetchDescriptor<CaptureEntry>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    /// Search entries by raw text (case-sensitive)
    func search(query: String) throws -> [CaptureEntry] {
        let descriptor = FetchDescriptor<CaptureEntry>(
            predicate: #Predicate { entry in
                entry.rawText.contains(query)
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    // MARK: - Update

    func update(entry: CaptureEntry) throws {
        try modelContext.save()
    }

    func updateLifecycleState(entry: CaptureEntry, to state: LifecycleState) throws {
        entry.currentLifecycleState = state
        try modelContext.save()
    }

    func setAcceptedSuggestion(entry: CaptureEntry, suggestion: Suggestion) throws {
        entry.acceptedSuggestion = suggestion
        entry.currentLifecycleState = .ready
        try modelContext.save()
    }

    // MARK: - Delete

    func delete(entry: CaptureEntry) throws {
        modelContext.delete(entry)
        try modelContext.save()
    }

    func archive(entry: CaptureEntry) throws {
        entry.currentLifecycleState = .archived
        try modelContext.save()
    }
}
