//
//  HandOffRun.swift
//  Offload
//
//  Created by Claude Code on 12/31/25.
//
//  Intent: Records each AI execution attempt for a hand-off request.
//  Captures prompt version, model, status, and errors for debugging and auditing.
//

import Foundation
import SwiftData

@Model
final class HandOffRun {
    var id: UUID
    var startedAt: Date
    var completedAt: Date?
    var modelId: String
    var promptVersion: String
    var inputSnapshot: String
    var runStatus: String // Stored as String for SwiftData compatibility
    var errorMessage: String?

    // Relationships
    @Relationship(deleteRule: .nullify)
    var handOffRequest: HandOffRequest?

    @Relationship(deleteRule: .cascade, inverse: \Suggestion.handOffRun)
    var suggestions: [Suggestion]?

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        completedAt: Date? = nil,
        modelId: String,
        promptVersion: String,
        inputSnapshot: String,
        runStatus: RunStatus = .running,
        errorMessage: String? = nil,
        handOffRequest: HandOffRequest? = nil,
        suggestions: [Suggestion]? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.modelId = modelId
        self.promptVersion = promptVersion
        self.inputSnapshot = inputSnapshot
        self.runStatus = runStatus.rawValue
        self.errorMessage = errorMessage
        self.handOffRequest = handOffRequest
        self.suggestions = suggestions
    }

    // Computed property for type-safe access to enum
    var status: RunStatus {
        get { RunStatus(rawValue: runStatus) ?? .running }
        set { runStatus = newValue.rawValue }
    }
}

// MARK: - RunStatus Enum

enum RunStatus: String, Codable, CaseIterable {
    case running
    case completed
    case failed
    case cancelled
}
