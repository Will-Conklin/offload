//
//  Project.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import Foundation
import SwiftData

@Model
final class Project {
    var id: UUID
    var name: String
    var notes: String?
    var color: String?
    var icon: String?
    var createdAt: Date
    var updatedAt: Date
    var archivedAt: Date?

    // TODO: Add relationship to Tasks
    // TODO: Add relationship to parent Project (for hierarchical projects)
    // TODO: Add relationship to subprojects
    // TODO: Add goal/outcome description
    // TODO: Add progress tracking

    init(
        id: UUID = UUID(),
        name: String,
        notes: String? = nil,
        color: String? = nil,
        icon: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.color = color
        self.icon = icon
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archivedAt = archivedAt
    }
}
