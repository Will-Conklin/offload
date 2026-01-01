//
//  CaptureEntry.swift
//  Offload
//
//  Created by Claude Code on 12/31/25.
//
//  Intent: Core capture entity for raw thoughts before organization.
//  Tracks lifecycle from raw capture → AI hand-off → placement in structure.
//  Uses String storage for enums (SwiftData compatibility) with computed properties for type safety.
//

import Foundation
import SwiftData

@Model
final class CaptureEntry {
    var id: UUID
    var createdAt: Date
    var rawText: String
    var inputType: String  // Stored as String for SwiftData compatibility
    var source: String     // Stored as String for SwiftData compatibility
    var lifecycleState: String  // Stored as String for SwiftData compatibility
    var acceptedSuggestionId: UUID?

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \HandOffRequest.captureEntry)
    var handOffRequests: [HandOffRequest]?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        rawText: String,
        inputType: InputType,
        source: CaptureSource,
        lifecycleState: LifecycleState = .raw,
        acceptedSuggestionId: UUID? = nil,
        handOffRequests: [HandOffRequest]? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.rawText = rawText
        self.inputType = inputType.rawValue
        self.source = source.rawValue
        self.lifecycleState = lifecycleState.rawValue
        self.acceptedSuggestionId = acceptedSuggestionId
        self.handOffRequests = handOffRequests
    }

    // Computed properties for type-safe access to enums
    var entryInputType: InputType {
        get { InputType(rawValue: inputType) ?? .text }
        set { inputType = newValue.rawValue }
    }

    var captureSource: CaptureSource {
        get { CaptureSource(rawValue: source) ?? .app }
        set { source = newValue.rawValue }
    }

    var currentLifecycleState: LifecycleState {
        get { LifecycleState(rawValue: lifecycleState) ?? .raw }
        set { lifecycleState = newValue.rawValue }
    }
}

// MARK: - InputType Enum

enum InputType: String, Codable, CaseIterable {
    case text = "text"
    case voice = "voice"
}

// MARK: - CaptureSource Enum

enum CaptureSource: String, Codable, CaseIterable {
    case app = "app"
    case shortcut = "shortcut"
    case shareSheet = "shareSheet"
    case widget = "widget"
}

// MARK: - LifecycleState Enum

enum LifecycleState: String, Codable, CaseIterable {
    case raw = "raw"
    case handedOff = "handedOff"
    case ready = "ready"
    case placed = "placed"
    case archived = "archived"
}
