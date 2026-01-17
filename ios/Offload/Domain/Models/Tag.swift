import Foundation
import SwiftData

// AGENT NAV
// - Model
// - Init


@Model
final class Tag {
    var id: UUID
    var name: String
    var color: String?
    var createdAt: Date

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
