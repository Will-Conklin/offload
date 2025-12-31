//
//  HandOffRepository.swift
//  Offload
//
//  Created by Claude Code on 12/31/25.
//
//  Intent: Manages hand-off requests and runs for AI organization workflow.
//  Tracks AI execution attempts, retries, and different model runs.
//

import Foundation
import SwiftData

/// Repository for HandOffRequest and HandOffRun CRUD operations and queries
final class HandOffRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - HandOffRequest Operations

    func createRequest(request: HandOffRequest) throws {
        modelContext.insert(request)
        try modelContext.save()
    }

    func fetchRequestById(_ id: UUID) throws -> HandOffRequest? {
        let descriptor = FetchDescriptor<HandOffRequest>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func fetchRequestsByEntry(_ entryId: UUID) throws -> [HandOffRequest] {
        let descriptor = FetchDescriptor<HandOffRequest>(
            predicate: #Predicate { request in
                request.brainDumpEntry?.id == entryId
            },
            sortBy: [SortDescriptor(\.requestedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchRequestsBySource(_ source: RequestSource) throws -> [HandOffRequest] {
        let descriptor = FetchDescriptor<HandOffRequest>(
            sortBy: [SortDescriptor(\.requestedAt, order: .reverse)]
        )
        let all = try modelContext.fetch(descriptor)
        return all.filter { $0.source == source }
    }

    func fetchAllRequests() throws -> [HandOffRequest] {
        let descriptor = FetchDescriptor<HandOffRequest>(
            sortBy: [SortDescriptor(\.requestedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func deleteRequest(request: HandOffRequest) throws {
        modelContext.delete(request)
        try modelContext.save()
    }

    // MARK: - HandOffRun Operations

    func createRun(run: HandOffRun) throws {
        modelContext.insert(run)
        try modelContext.save()
    }

    func fetchRunById(_ id: UUID) throws -> HandOffRun? {
        let descriptor = FetchDescriptor<HandOffRun>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func fetchRunsByRequest(_ requestId: UUID) throws -> [HandOffRun] {
        let descriptor = FetchDescriptor<HandOffRun>(
            predicate: #Predicate { run in
                run.handOffRequest?.id == requestId
            },
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchRunsByStatus(_ status: RunStatus) throws -> [HandOffRun] {
        let descriptor = FetchDescriptor<HandOffRun>(
            sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
        )
        let all = try modelContext.fetch(descriptor)
        return all.filter { $0.status == status }
    }

    func updateRunStatus(run: HandOffRun, status: RunStatus, errorMessage: String? = nil) throws {
        run.status = status
        run.errorMessage = errorMessage
        if status == .completed || status == .failed || status == .cancelled {
            run.completedAt = Date()
        }
        try modelContext.save()
    }

    func deleteRun(run: HandOffRun) throws {
        modelContext.delete(run)
        try modelContext.save()
    }
}
