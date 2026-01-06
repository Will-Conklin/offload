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
import SwiftData
import Observation

@Observable
@MainActor
final class CaptureWorkflowService {
    // MARK: - Published State

    private(set) var isProcessing = false
    private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let captureRepo: CaptureRepository
    private let handOffRepo: HandOffRepository
    private let suggestionRepo: SuggestionRepository
    private let placementRepo: PlacementRepository
    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.captureRepo = CaptureRepository(modelContext: modelContext)
        self.handOffRepo = HandOffRepository(modelContext: modelContext)
        self.suggestionRepo = SuggestionRepository(modelContext: modelContext)
        self.placementRepo = PlacementRepository(modelContext: modelContext)
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
            _Concurrency.Task { @MainActor in
                self.isProcessing = false
            }
        }

        do {
            let entry = CaptureEntry(
                rawText: rawText,
                inputType: inputType,
                source: source,
                lifecycleState: .raw
            )

            try captureRepo.create(entry: entry)
            return entry
        } catch {
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
            _Concurrency.Task { @MainActor in
                self.isProcessing = false
            }
        }

        do {
            try captureRepo.updateLifecycleState(entry: entry, to: .archived)
        } catch {
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
            _Concurrency.Task { @MainActor in
                self.isProcessing = false
            }
        }

        do {
            try captureRepo.delete(entry: entry)
        } catch {
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
            errorMessage = error.localizedDescription
            throw WorkflowError.unknownError(error.localizedDescription)
        }
    }

    /// Fetch entries by lifecycle state
    func fetchByState(_ state: LifecycleState) throws -> [CaptureEntry] {
        do {
            return try captureRepo.fetchByState(state)
        } catch {
            errorMessage = error.localizedDescription
            throw WorkflowError.unknownError(error.localizedDescription)
        }
    }

    /// Fetch entries awaiting placement (ready state)
    func fetchAwaitingPlacement() throws -> [CaptureEntry] {
        do {
            return try captureRepo.fetchReady()
        } catch {
            errorMessage = error.localizedDescription
            throw WorkflowError.unknownError(error.localizedDescription)
        }
    }

    /// Full-text search on raw text
    func searchEntries(_ query: String) throws -> [CaptureEntry] {
        do {
            return try captureRepo.search(query: query)
        } catch {
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
