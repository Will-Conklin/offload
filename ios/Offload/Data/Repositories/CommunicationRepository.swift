//
//  CommunicationRepository.swift
//  Offload
//
//  Created by Claude Code on 12/31/25.
//
//  Intent: Manages communication reminders (calls, emails, texts).
//  Helps track "remember to tell X about Y" captured thoughts.
//

import Foundation
import SwiftData

/// Repository for CommunicationItem CRUD operations and queries
final class CommunicationRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create

    func create(item: CommunicationItem) throws {
        modelContext.insert(item)
        try modelContext.save()
    }

    // MARK: - Read

    func fetchAll() throws -> [CommunicationItem] {
        let descriptor = FetchDescriptor<CommunicationItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchById(_ id: UUID) throws -> CommunicationItem? {
        let descriptor = FetchDescriptor<CommunicationItem>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func fetchByChannel(_ channel: CommunicationChannel) throws -> [CommunicationItem] {
        let rawChannel = channel.rawValue
        let descriptor = FetchDescriptor<CommunicationItem>(
            predicate: #Predicate { item in
                item.channel == rawChannel
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchByStatus(_ status: CommunicationStatus) throws -> [CommunicationItem] {
        let rawStatus = status.rawValue
        let descriptor = FetchDescriptor<CommunicationItem>(
            predicate: #Predicate { item in
                item.status == rawStatus
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchByRecipient(_ recipient: String) throws -> [CommunicationItem] {
        let descriptor = FetchDescriptor<CommunicationItem>(
            predicate: #Predicate { item in
                item.recipient.contains(recipient)
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// Fetch draft communications (not yet sent)
    func fetchDrafts() throws -> [CommunicationItem] {
        try fetchByStatus(.draft)
    }

    // MARK: - Update

    func update(item _: CommunicationItem) throws {
        try modelContext.save()
    }

    func markAsSent(item: CommunicationItem) throws {
        item.communicationStatus = .sent
        try modelContext.save()
    }

    func markAsDeferred(item: CommunicationItem) throws {
        item.communicationStatus = .deferred
        try modelContext.save()
    }

    // MARK: - Delete

    func delete(item: CommunicationItem) throws {
        modelContext.delete(item)
        try modelContext.save()
    }
}
