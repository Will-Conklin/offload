//
//  Suggestion.swift
//  Offload
//
//  Created by Claude Code on 12/31/25.
//
//  Intent: AI-generated organization suggestions from a hand-off run.
//  Stores structured data (plan, task, list, etc.) as versioned JSON for flexibility.
//

import Foundation
import SwiftData

@Model
final class Suggestion {
    var id: UUID
    var kind: String // Stored as String for SwiftData compatibility
    var payloadJSON: String // Versioned JSON blob
    var confidence: Double?

    // Relationships
    @Relationship(deleteRule: .nullify)
    var handOffRun: HandOffRun?

    @Relationship(deleteRule: .cascade, inverse: \SuggestionDecision.suggestion)
    var decisions: [SuggestionDecision]?

    init(
        id: UUID = UUID(),
        kind: SuggestionKind,
        payloadJSON: String,
        confidence: Double? = nil,
        handOffRun: HandOffRun? = nil,
        decisions: [SuggestionDecision]? = nil
    ) {
        self.id = id
        self.kind = kind.rawValue
        self.payloadJSON = payloadJSON
        self.confidence = confidence
        self.handOffRun = handOffRun
        self.decisions = decisions
    }

    // Computed property for type-safe access to enum
    var suggestionKind: SuggestionKind {
        get { SuggestionKind(rawValue: kind) ?? .task }
        set { kind = newValue.rawValue }
    }
}

// MARK: - SuggestionKind Enum

enum SuggestionKind: String, Codable, CaseIterable {
    case plan
    case task
    case list
    case communication
    case mixed
}
