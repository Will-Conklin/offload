// Purpose: SwiftData model definitions.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Maintain explicit type references in predicates and preserve relationship rules.

import Foundation
import SwiftData



@Model
final class Tag {
    var id: UUID
    var name: String
    var color: String?
    var createdAt: Date
    var items: [Item]

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
        self.items = []
    }
}
