//
//  Placement.swift
//  Offload
//
//  Created by Claude Code on 12/31/25.
//
//  Intent: Audit trail linking accepted AI suggestions to their final destination.
//  Uses UUID references (not SwiftData relationships) for flexibility and loose coupling.
//

import Foundation
import SwiftData

@Model
final class Placement {
    var id: UUID
    var placedAt: Date
    var targetType: String // Stored as String for SwiftData compatibility
    var targetId: UUID // UUID reference to target entity
    var sourceSuggestionId: UUID
    var notes: String?

    // No SwiftData relationships - uses UUID references for flexibility
    // This allows audit trail without tight coupling to target entities

    init(
        id: UUID = UUID(),
        placedAt: Date = Date(),
        targetType: PlacementTargetType,
        targetId: UUID,
        sourceSuggestionId: UUID,
        notes: String? = nil
    ) {
        self.id = id
        self.placedAt = placedAt
        self.targetType = targetType.rawValue
        self.targetId = targetId
        self.sourceSuggestionId = sourceSuggestionId
        self.notes = notes
    }

    // Computed property for type-safe access to enum
    var target: PlacementTargetType {
        get { PlacementTargetType(rawValue: targetType) ?? .task }
        set { targetType = newValue.rawValue }
    }
}

// MARK: - PlacementTargetType Enum

enum PlacementTargetType: String, Codable, CaseIterable {
    case plan
    case task
    case list
    case listItem
    case communication
}
