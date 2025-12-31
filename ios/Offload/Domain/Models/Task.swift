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

    // TODO: Add relationship to Project
    // TODO: Add relationship to Tags
    // TODO: Add relationship to Category
    // TODO: Add attachments
    // TODO: Add subtasks
    // TODO: Add recurrence rules

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        completedAt: Date? = nil,
        dueDate: Date? = nil,
        priority: Priority = .medium,
        status: TaskStatus = .inbox
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
