//
//  RepositoryProtocols.swift
//  Offload
//
//  Created by Claude Code on 1/7/26.
//
//  Intent: Define repository protocols to enable dependency injection and
//  testable data access across workflow services.
//

import Foundation

protocol CaptureRepositoryProtocol {
    func create(entry: CaptureEntry) throws
    func fetchAll() throws -> [CaptureEntry]
    func fetchInbox() throws -> [CaptureEntry]
    func fetchByState(_ state: LifecycleState) throws -> [CaptureEntry]
    func fetchReady() throws -> [CaptureEntry]
    func search(query: String) throws -> [CaptureEntry]
    func update(entry: CaptureEntry) throws
    func updateLifecycleState(entry: CaptureEntry, to state: LifecycleState) throws
    func delete(entry: CaptureEntry) throws
}

protocol SuggestionRepositoryProtocol {
    func createSuggestion(suggestion: Suggestion) throws
    func fetchSuggestionById(_ id: UUID) throws -> Suggestion?
    func fetchSuggestionsByRun(_ runId: UUID) throws -> [Suggestion]
    func fetchSuggestionsByKind(_ kind: SuggestionKind) throws -> [Suggestion]
    func fetchAllSuggestions() throws -> [Suggestion]
    func fetchPendingSuggestionsForEntry(_ entryId: UUID) throws -> [Suggestion]
    func deleteSuggestion(suggestion: Suggestion) throws
    func recordDecision(decision: SuggestionDecision) throws
    func fetchDecisionById(_ id: UUID) throws -> SuggestionDecision?
    func fetchDecisionsBySuggestion(_ suggestionId: UUID) throws -> [SuggestionDecision]
    func fetchDecisionsByType(_ type: DecisionType) throws -> [SuggestionDecision]
    func deleteDecision(decision: SuggestionDecision) throws
}

protocol HandOffRepositoryProtocol {
    func createRequest(request: HandOffRequest) throws
    func fetchRequestById(_ id: UUID) throws -> HandOffRequest?
    func fetchRequestsByEntry(_ entryId: UUID) throws -> [HandOffRequest]
    func fetchRequestsBySource(_ source: RequestSource) throws -> [HandOffRequest]
    func fetchAllRequests() throws -> [HandOffRequest]
    func deleteRequest(request: HandOffRequest) throws
    func createRun(run: HandOffRun) throws
    func fetchRunById(_ id: UUID) throws -> HandOffRun?
    func fetchRunsByRequest(_ requestId: UUID) throws -> [HandOffRun]
    func fetchRunsByStatus(_ status: RunStatus) throws -> [HandOffRun]
    func updateRunStatus(run: HandOffRun, status: RunStatus, errorMessage: String?) throws
    func deleteRun(run: HandOffRun) throws
}
