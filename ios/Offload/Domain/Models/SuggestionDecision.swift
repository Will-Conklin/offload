//
//  SuggestionDecision.swift
//  Offload
//
//  Created by Claude Code on 12/31/25.
//
//  Intent: Tracks user's response to AI suggestions (accept/notNow).
//  Supports undo workflow and learning from user preferences.
//

import Foundation
import SwiftData

@Model
final class SuggestionDecision {
    var id: UUID
    var decision: String // Stored as String for SwiftData compatibility
    var decidedAt: Date
    var decidedBy: String // Stored as String for SwiftData compatibility
    var undoOfDecisionId: UUID?

    // Relationships
    @Relationship(deleteRule: .nullify)
    var suggestion: Suggestion?

    init(
        id: UUID = UUID(),
        decision: DecisionType,
        decidedAt: Date = Date(),
        decidedBy: DecisionSource,
        undoOfDecisionId: UUID? = nil,
        suggestion: Suggestion? = nil
    ) {
        self.id = id
        self.decision = decision.rawValue
        self.decidedAt = decidedAt
        self.decidedBy = decidedBy.rawValue
        self.undoOfDecisionId = undoOfDecisionId
        self.suggestion = suggestion
    }

    // Computed properties for type-safe access to enums
    var decisionType: DecisionType {
        get { DecisionType(rawValue: decision) ?? .notNow }
        set { decision = newValue.rawValue }
    }

    var source: DecisionSource {
        get { DecisionSource(rawValue: decidedBy) ?? .user }
        set { decidedBy = newValue.rawValue }
    }
}

// MARK: - DecisionType Enum

enum DecisionType: String, Codable, CaseIterable {
    case accepted
    case notNow
    case rejected
}

// MARK: - DecisionSource Enum

enum DecisionSource: String, Codable, CaseIterable {
    case user
    case system
}
