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
        let all = try fetchAllSuggestions()
        return all.filter { $0.suggestionKind == kind }
    }

    func fetchAllSuggestions() throws -> [Suggestion] {
        let descriptor = FetchDescriptor<Suggestion>()
        return try modelContext.fetch(descriptor)
    }

    /// Fetch pending suggestions (no accepted decision) for a brain dump entry
    func fetchPendingSuggestionsForEntry(_ entryId: UUID) throws -> [Suggestion] {
        let descriptor: FetchDescriptor<Suggestion> = FetchDescriptor(
            predicate: #Predicate<Suggestion> { suggestion in
                suggestion.handOffRun?.handOffRequest?.captureEntry?.id == entryId
            }
        )
        let suggestions: [Suggestion] = try modelContext.fetch(descriptor)

        // Filter to only suggestions without an accepted decision
        return suggestions.filter { suggestion in
            guard let decisions = suggestion.decisions else { return true }
            return !decisions.contains { $0.decisionType == .accepted }
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
        let descriptor = FetchDescriptor<SuggestionDecision>(
            sortBy: [SortDescriptor(\.decidedAt, order: .reverse)]
        )
        let all = try modelContext.fetch(descriptor)
        return all.filter { $0.decisionType == type }
    }

    func deleteDecision(decision: SuggestionDecision) throws {
        modelContext.delete(decision)
        try modelContext.save()
    }
}
