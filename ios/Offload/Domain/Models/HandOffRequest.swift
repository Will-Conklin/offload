//
//  HandOffRequest.swift
//  Offload
//
//  Created by Claude Code on 12/31/25.
//
//  Intent: Tracks when user requests AI to organize a thought capture.
//  Each request can have multiple runs (retries, different AI models, etc.).
//

import Foundation
import SwiftData

@Model
final class HandOffRequest {
    var id: UUID
    var requestedAt: Date
    var requestedBy: String // Stored as String for SwiftData compatibility
    var mode: String // Stored as String for SwiftData compatibility

    // Relationships
    @Relationship(deleteRule: .nullify)
    var captureEntry: CaptureEntry?

    @Relationship(deleteRule: .cascade, inverse: \HandOffRun.handOffRequest)
    var runs: [HandOffRun]?

    init(
        id: UUID = UUID(),
        requestedAt: Date = Date(),
        requestedBy: RequestSource,
        mode: HandOffMode,
        captureEntry: CaptureEntry? = nil,
        runs: [HandOffRun]? = nil
    ) {
        self.id = id
        self.requestedAt = requestedAt
        self.requestedBy = requestedBy.rawValue
        self.mode = mode.rawValue
        self.captureEntry = captureEntry
        self.runs = runs
    }

    // Computed properties for type-safe access to enums
    var source: RequestSource {
        get { RequestSource(rawValue: requestedBy) ?? .user }
        set { requestedBy = newValue.rawValue }
    }

    var handOffMode: HandOffMode {
        get { HandOffMode(rawValue: mode) ?? .manual }
        set { mode = newValue.rawValue }
    }
}

// MARK: - RequestSource Enum

enum RequestSource: String, Codable, CaseIterable {
    case user
    case auto
    case scheduled
}

// MARK: - HandOffMode Enum

enum HandOffMode: String, Codable, CaseIterable {
    case manual
    case auto
}
