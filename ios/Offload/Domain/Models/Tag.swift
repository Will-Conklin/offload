import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    var name: String
    var color: String?
    var createdAt: Date

    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \Task.tags)
    var tasks: [Task]?

    init(
        id: UUID = UUID(),
        name: String,
        color: String? = nil,
        createdAt: Date = Date(),
        tasks: [Task]? = nil
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.createdAt = createdAt
        self.tasks = tasks
    }
}
