//
//  Task.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import Foundation
import SwiftData

@Model
final class Task {
    var id: UUID
    var title: String
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    var dueDate: Date?
    var priority: Priority
    var status: TaskStatus

    // Relationships
    var project: Project?
    var category: Category?
    var tags: [Tag]?
    var blockedBy: [Task]?
    var sourceThought: Thought?

    // TODO: Add attachments (Phase 3+)
    // TODO: Add subtasks (Phase 4+)
    // TODO: Add recurrence rules (Phase 5+)

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil,
        dueDate: Date? = nil,
        priority: Priority = .medium,
        status: TaskStatus = .inbox,
        project: Project? = nil,
        category: Category? = nil,
        tags: [Tag]? = nil,
        blockedBy: [Task]? = nil,
        sourceThought: Thought? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completedAt = completedAt
        self.dueDate = dueDate
        self.priority = priority
        self.status = status
        self.project = project
        self.category = category
        self.tags = tags
        self.blockedBy = blockedBy
        self.sourceThought = sourceThought
    }
}

enum Priority: String, Codable, CaseIterable {
    case low
    case medium
    case high
    case urgent
}

enum TaskStatus: String, Codable, CaseIterable {
    case inbox
    case next
    case waiting
    case someday
    case completed
    case archived
}
