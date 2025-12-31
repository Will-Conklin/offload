//
//  BrainDumpWorkflowService.swift
//  Offload
//
//  Created by Claude Code on 12/31/25.
//
//  Intent: Orchestrates the brain dump capture → organization → placement workflow.
//  Provides high-level business operations for SwiftUI views.
//

import Foundation
import SwiftData
import Observation

@Observable
@MainActor
final class BrainDumpWorkflowService {
    // MARK: - Published State

    var isProcessing = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let brainDumpRepo: BrainDumpRepository
    private let handOffRepo: HandOffRepository
    private let suggestionRepo: SuggestionRepository
    private let placementRepo: PlacementRepository
    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.brainDumpRepo = BrainDumpRepository(modelContext: modelContext)
        self.handOffRepo = HandOffRepository(modelContext: modelContext)
        self.suggestionRepo = SuggestionRepository(modelContext: modelContext)
        self.placementRepo = PlacementRepository(modelContext: modelContext)
    }

    // MARK: - Capture Operations

    /// Capture a new brain dump entry
    func captureEntry(
        rawText: String,
        inputType: InputType,
        source: CaptureSource
    ) async throws -> BrainDumpEntry {
        guard !isProcessing else {
            throw WorkflowError.alreadyProcessing
        }

        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        do {
            let entry = BrainDumpEntry(
                rawText: rawText,
                inputType: inputType,
                source: source,
                lifecycleState: .raw
            )

            try brainDumpRepo.create(entry: entry)
            return entry
        } catch {
            errorMessage = error.localizedDescription
            throw WorkflowError.unknownError(error.localizedDescription)
        }
    }

    /// Archive an entry (marks as archived, no deletion)
    func archiveEntry(_ entry: BrainDumpEntry) async throws {
        guard !isProcessing else {
            throw WorkflowError.alreadyProcessing
        }

        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        do {
            try brainDumpRepo.updateLifecycleState(entry: entry, to: .archived)
        } catch {
            errorMessage = error.localizedDescription
            throw WorkflowError.unknownError(error.localizedDescription)
        }
    }

    /// Permanently delete an entry
    func deleteEntry(_ entry: BrainDumpEntry) async throws {
        guard !isProcessing else {
            throw WorkflowError.alreadyProcessing
        }

        isProcessing = true
        errorMessage = nil
        defer { isProcessing = false }

        do {
            try brainDumpRepo.delete(entry: entry)
        } catch {
            errorMessage = error.localizedDescription
            throw WorkflowError.unknownError(error.localizedDescription)
        }
    }

    // MARK: - Query Operations

    /// Fetch inbox entries (raw state)
    func fetchInbox() throws -> [BrainDumpEntry] {
        do {
            return try brainDumpRepo.fetchInbox()
        } catch {
            errorMessage = error.localizedDescription
            throw WorkflowError.unknownError(error.localizedDescription)
        }
    }

    /// Fetch entries by lifecycle state
    func fetchByState(_ state: LifecycleState) throws -> [BrainDumpEntry] {
        do {
            return try brainDumpRepo.fetchByState(state)
        } catch {
            errorMessage = error.localizedDescription
            throw WorkflowError.unknownError(error.localizedDescription)
        }
    }

    /// Fetch entries awaiting placement (ready state)
    func fetchAwaitingPlacement() throws -> [BrainDumpEntry] {
        do {
            return try brainDumpRepo.fetchReady()
        } catch {
            errorMessage = error.localizedDescription
            throw WorkflowError.unknownError(error.localizedDescription)
        }
    }

    /// Full-text search on raw text
    func searchEntries(_ query: String) throws -> [BrainDumpEntry] {
        do {
            return try brainDumpRepo.search(query: query)
        } catch {
            errorMessage = error.localizedDescription
            throw WorkflowError.unknownError(error.localizedDescription)
        }
    }

    // MARK: - Workflow Operations (Stub for Future)

    /// Submit an entry for AI organization (not yet implemented)
    func submitForOrganization(
        _ entry: BrainDumpEntry,
        mode: HandOffMode = .manual
    ) async throws {
        throw WorkflowError.notImplemented
    }

    /// Fetch suggestions for an entry (not yet implemented)
    func fetchSuggestions(for entry: BrainDumpEntry) throws -> [Suggestion] {
        throw WorkflowError.notImplemented
    }

    /// Accept a suggestion and place it (not yet implemented)
    func acceptSuggestion(
        _ suggestion: Suggestion,
        for entry: BrainDumpEntry
    ) async throws {
        throw WorkflowError.notImplemented
    }

    /// Reject a suggestion (not yet implemented)
    func rejectSuggestion(
        _ suggestion: Suggestion,
        reason: DecisionType = .notNow
    ) async throws {
        throw WorkflowError.notImplemented
    }
}

// MARK: - Errors

enum WorkflowError: LocalizedError {
    case invalidState(String)
    case alreadyProcessing
    case notImplemented
    case unknownError(String)

    var errorDescription: String? {
        switch self {
        case .invalidState(let msg):
            return "Invalid state: \(msg)"
        case .alreadyProcessing:
            return "Another operation is already in progress"
        case .notImplemented:
            return "This feature is not yet implemented"
        case .unknownError(let msg):
            return msg
        }
    }
}
