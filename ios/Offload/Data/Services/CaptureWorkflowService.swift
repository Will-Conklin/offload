//
//  CaptureWorkflowService.swift
//  Offload
//
//  Created by Claude Code on 12/31/25.
//
//  Intent: Orchestrates the thought capture → organization → placement workflow.
//  Provides high-level business operations for SwiftUI views.
//

import Foundation
import OSLog
import SwiftData
import Observation

@Observable
@MainActor
final class CaptureWorkflowService {
    // MARK: - Published State

    internal(set) var isProcessing = false
    internal(set) var errorMessage: String?

    // MARK: - Dependencies

    private let captureRepo: CaptureRepositoryProtocol
    private let handOffRepo: HandOffRepositoryProtocol
    private let suggestionRepo: SuggestionRepositoryProtocol
    private let placementRepo: PlacementRepository
    private let modelContext: ModelContext

    // MARK: - Initialization

    init(
        modelContext: ModelContext,
        captureRepo: CaptureRepositoryProtocol? = nil,
        handOffRepo: HandOffRepositoryProtocol? = nil,
        suggestionRepo: SuggestionRepositoryProtocol? = nil,
        placementRepo: PlacementRepository? = nil
    ) {
        self.modelContext = modelContext
        self.captureRepo = captureRepo ?? CaptureRepository(modelContext: modelContext)
        self.handOffRepo = handOffRepo ?? HandOffRepository(modelContext: modelContext)
        self.suggestionRepo = suggestionRepo ?? SuggestionRepository(modelContext: modelContext)
        self.placementRepo = placementRepo ?? PlacementRepository(modelContext: modelContext)
    }

    // MARK: - Capture Operations

    /// Capture a new thought entry
    func captureEntry(
        rawText: String,
        inputType: InputType,
        source: CaptureSource
    ) async throws -> CaptureEntry {
        guard !isProcessing else {
            throw WorkflowError.alreadyProcessing
        }

        isProcessing = true
        errorMessage = nil
        defer {
            isProcessing = false
        }

        do {
            AppLogger.workflow.info("Capturing entry from \(source.rawValue, privacy: .public)")
            let entry = CaptureEntry(
                rawText: rawText,
                inputType: inputType,
                source: source,
                lifecycleState: .raw
            )

            try captureRepo.create(entry: entry)
            AppLogger.workflow.debug("Created capture entry \(entry.id, privacy: .public)")
            return entry
        } catch {
            AppLogger.workflow.error("Capture entry failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = error.localizedDescription
            throw WorkflowError.unknownError(error.localizedDescription)
        }
    }

    /// Archive an entry (marks as archived, no deletion)
    func archiveEntry(_ entry: CaptureEntry) async throws {
        guard !isProcessing else {
            throw WorkflowError.alreadyProcessing
        }

        isProcessing = true
        errorMessage = nil
        defer {
            isProcessing = false
        }

        do {
            AppLogger.workflow.info("Archiving capture entry \(entry.id, privacy: .public)")
            try captureRepo.updateLifecycleState(entry: entry, to: .archived)
        } catch {
            AppLogger.workflow.error("Archive entry failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = error.localizedDescription
            throw WorkflowError.unknownError(error.localizedDescription)
        }
    }

    /// Permanently delete an entry
    func deleteEntry(_ entry: CaptureEntry) async throws {
        guard !isProcessing else {
            throw WorkflowError.alreadyProcessing
        }

        isProcessing = true
        errorMessage = nil
        defer {
            isProcessing = false
        }

        do {
            AppLogger.workflow.info("Deleting capture entry \(entry.id, privacy: .public)")
            try captureRepo.delete(entry: entry)
        } catch {
            AppLogger.workflow.error("Delete entry failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = error.localizedDescription
            throw WorkflowError.unknownError(error.localizedDescription)
        }
    }

    // MARK: - Query Operations

    /// Fetch inbox entries (raw state)
    func fetchInbox() throws -> [CaptureEntry] {
        do {
            return try captureRepo.fetchInbox()
        } catch {
            AppLogger.workflow.error("Fetch inbox failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = error.localizedDescription
            throw WorkflowError.unknownError(error.localizedDescription)
        }
    }

    /// Fetch entries by lifecycle state
    func fetchByState(_ state: LifecycleState) throws -> [CaptureEntry] {
        do {
            return try captureRepo.fetchByState(state)
        } catch {
            AppLogger.workflow.error("Fetch by state failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = error.localizedDescription
            throw WorkflowError.unknownError(error.localizedDescription)
        }
    }

    /// Fetch entries awaiting placement (ready state)
    func fetchAwaitingPlacement() throws -> [CaptureEntry] {
        do {
            return try captureRepo.fetchReady()
        } catch {
            AppLogger.workflow.error("Fetch awaiting placement failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = error.localizedDescription
            throw WorkflowError.unknownError(error.localizedDescription)
        }
    }

    /// Full-text search on raw text
    func searchEntries(_ query: String) throws -> [CaptureEntry] {
        do {
            return try captureRepo.search(query: query)
        } catch {
            AppLogger.workflow.error("Search entries failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = error.localizedDescription
            throw WorkflowError.unknownError(error.localizedDescription)
        }
    }

    // MARK: - Workflow Operations (Stub for Future)

    /// Submit an entry for AI organization (not yet implemented)
    func submitForOrganization(
        _ entry: CaptureEntry,
        mode: HandOffMode = .manual
    ) async throws {
        throw WorkflowError.notImplemented
    }

    /// Fetch suggestions for an entry (not yet implemented)
    func fetchSuggestions(for entry: CaptureEntry) throws -> [Suggestion] {
        throw WorkflowError.notImplemented
    }

    /// Accept a suggestion and place it (not yet implemented)
    func acceptSuggestion(
        _ suggestion: Suggestion,
        for entry: CaptureEntry
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
