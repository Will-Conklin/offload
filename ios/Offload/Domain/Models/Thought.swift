//
//  Thought.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import Foundation
import SwiftData

@Model
final class Thought {
    var id: UUID
    var createdAt: Date
    var source: String
    var rawText: String
    var status: String

    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Task.sourceThought)
    var derivedTasks: [Task]?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        source: ThoughtSource,
        rawText: String,
        status: ThoughtStatus = .inbox,
        derivedTasks: [Task]? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.source = source.rawValue
        self.rawText = rawText
        self.status = status.rawValue
        self.derivedTasks = derivedTasks
    }

    // Computed properties for type-safe access to enums
    var thoughtSource: ThoughtSource {
        get { ThoughtSource(rawValue: source) ?? .manual }
        set { source = newValue.rawValue }
    }

    var thoughtStatus: ThoughtStatus {
        get { ThoughtStatus(rawValue: status) ?? .captured }
        set { status = newValue.rawValue }
    }
}

// MARK: - ThoughtSource Enum

enum ThoughtSource: String, Codable, CaseIterable {
    case text = "text"
    case manual = "manual"
    case voice = "voice"
    case clipboard = "clipboard"
    case share = "share"
    case widget = "widget"
}

// MARK: - ThoughtStatus Enum

enum ThoughtStatus: String, Codable, CaseIterable {
    case inbox = "inbox"
    case captured = "captured"
    case processing = "processing"
    case processed = "processed"
    case archived = "archived"
}
