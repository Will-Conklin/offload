//
//  ListEntity.swift
//  Offload
//
//  Created by Claude Code on 12/31/25.
//
//  Intent: Container for simple lists (shopping, packing, reference).
//  Lighter-weight alternative to tasks for checklist-style items.
//

import Foundation
import SwiftData

@Model
final class ListEntity {
    var id: UUID
    var title: String
    var kind: String // Stored as String for SwiftData compatibility
    var createdAt: Date

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \ListItem.list)
    var items: [ListItem]?

    init(
        id: UUID = UUID(),
        title: String,
        kind: ListKind,
        createdAt: Date = Date(),
        items: [ListItem]? = nil
    ) {
        self.id = id
        self.title = title
        self.kind = kind.rawValue
        self.createdAt = createdAt
        self.items = items
    }

    // Computed property for type-safe access to enum
    var listKind: ListKind {
        get { ListKind(rawValue: kind) ?? .reference }
        set { kind = newValue.rawValue }
    }
}

// MARK: - ListKind Enum

enum ListKind: String, Codable, CaseIterable {
    case shopping
    case packing
    case reference
}
