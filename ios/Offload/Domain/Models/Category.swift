//
//  Category.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import Foundation
import SwiftData

@Model
final class Category {
    var id: UUID
    var name: String
    var icon: String?
    var createdAt: Date

    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Task.category)
    var tasks: [Task]?

    // TODO: Add ordering/sorting (Phase 3+)

    init(
        id: UUID = UUID(),
        name: String,
        icon: String? = nil,
        createdAt: Date = Date(),
        tasks: [Task]? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.createdAt = createdAt
        self.tasks = tasks
    }
}
