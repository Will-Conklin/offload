//
//  SuggestionRepository.swift
//  Offload
//
//  Created by Claude Code on 12/31/25.
//
//  Intent: Manages AI-generated suggestions and user decisions.
//  Tracks suggestion lifecycle from creation through acceptance/rejection.
//

import Foundation
import SwiftData

/// Repository for Suggestion and SuggestionDecision CRUD operations and queries
final class SuggestionRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Suggestion Operations

    func createSuggestion(suggestion: Suggestion) throws {
        modelContext.insert(suggestion)
        try modelContext.save()
    }

    func fetchSuggestionById(_ id: UUID) throws -> Suggestion? {
        let descriptor = FetchDescriptor<Suggestion>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func fetchSuggestionsByRun(_ runId: UUID) throws -> [Suggestion] {
        let descriptor = FetchDescriptor<Suggestion>(
            predicate: #Predicate { suggestion in
                suggestion.handOffRun?.id == runId
            }
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchSuggestionsByKind(_ kind: SuggestionKind) throws -> [Suggestion] {
        let rawValue = kind.rawValue
        let predicate = #Predicate<Suggestion> { $0.kind == rawValue }
        let descriptor = FetchDescriptor<Suggestion>(predicate: predicate)
        return try modelContext.fetch(descriptor)
    }

    func fetchAllSuggestions() throws -> [Suggestion] {
        let descriptor = FetchDescriptor<Suggestion>()
        return try modelContext.fetch(descriptor)
    }

    /// Fetch pending suggestions (no accepted decision) for a capture entry
    func fetchPendingSuggestionsForEntry(_ entryId: UUID) throws -> [Suggestion] {
        // SwiftData predicates do not support optional chaining across relationships.
        let suggestions = try fetchAllSuggestions()
        let entrySuggestions = suggestions.filter { suggestion in
            suggestion.handOffRun?.handOffRequest?.captureEntry?.id == entryId
        }

        // Filter to only suggestions without an accepted decision
        return entrySuggestions.filter { suggestion in
            guard let decisions = suggestion.decisions else { return true }
            return !decisions.contains { $0.decisionType == DecisionType.accepted }
        }
    }

    func deleteSuggestion(suggestion: Suggestion) throws {
        modelContext.delete(suggestion)
        try modelContext.save()
    }

    // MARK: - Decision Operations

    func recordDecision(decision: SuggestionDecision) throws {
        modelContext.insert(decision)
        try modelContext.save()
    }

    func fetchDecisionById(_ id: UUID) throws -> SuggestionDecision? {
        let descriptor = FetchDescriptor<SuggestionDecision>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func fetchDecisionsBySuggestion(_ suggestionId: UUID) throws -> [SuggestionDecision] {
        let descriptor = FetchDescriptor<SuggestionDecision>(
            predicate: #Predicate { decision in
                decision.suggestion?.id == suggestionId
            },
            sortBy: [SortDescriptor(\.decidedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchDecisionsByType(_ type: DecisionType) throws -> [SuggestionDecision] {
        let rawValue = type.rawValue
        let predicate = #Predicate<SuggestionDecision> { $0.decision == rawValue }
        let descriptor = FetchDescriptor<SuggestionDecision>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.decidedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func deleteDecision(decision: SuggestionDecision) throws {
        modelContext.delete(decision)
        try modelContext.save()
    }
}
