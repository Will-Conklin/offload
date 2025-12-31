//
//  Task.swift
//  Offload
//
//  Created by Claude Code on 12/31/25.
//
//  Intent: Simplified task model for structured to-dos created from brain dumps.
//  Uses importance scale (1-5) instead of priority enum to reduce cognitive load.
//

import Foundation
import SwiftData

@Model
final class Task {
    var id: UUID
    var title: String
    var detail: String?
    var createdAt: Date
    var isDone: Bool
    var importance: Int // 1-5 scale
    var dueDate: Date?

    // Relationships
    @Relationship(deleteRule: .nullify)
    var plan: Plan?

    var category: Category?

    @Relationship(deleteRule: .nullify)
    var tags: [Tag]?

    init(
        id: UUID = UUID(),
        title: String,
        detail: String? = nil,
        createdAt: Date = Date(),
        isDone: Bool = false,
        importance: Int = 3,
        dueDate: Date? = nil,
        plan: Plan? = nil,
        category: Category? = nil,
        tags: [Tag]? = nil
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.createdAt = createdAt
        self.isDone = isDone
        self.importance = min(max(importance, 1), 5) // Clamp between 1-5
        self.dueDate = dueDate
        self.plan = plan
        self.category = category
        self.tags = tags
    }
}
