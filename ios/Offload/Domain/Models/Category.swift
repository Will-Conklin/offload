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

    // TODO: Add relationship to Tasks
    // TODO: Add ordering/sorting

    init(
        id: UUID = UUID(),
        name: String,
        icon: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.createdAt = createdAt
    }
}
