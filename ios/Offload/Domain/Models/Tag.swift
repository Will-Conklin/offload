//
//  Tag.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    var name: String
    var color: String?
    var createdAt: Date

    // TODO: Add relationship to Tasks (many-to-many)
    // TODO: Add sorting/ordering

    init(
        id: UUID = UUID(),
        name: String,
        color: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.createdAt = createdAt
    }
}
