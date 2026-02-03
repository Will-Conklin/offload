// Purpose: SwiftData model definitions.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Maintain explicit type references in predicates and preserve relationship rules.

import Foundation
import SwiftData

@Model
final class Collection {
    var id: UUID
    var name: String
    var isStructured: Bool // false = simple list, true = plan with order/hierarchy
    var createdAt: Date
    var isStarred: Bool

    // Relationship to items through CollectionItem
    @Relationship(deleteRule: .cascade, inverse: \CollectionItem.collection)
    var collectionItems: [CollectionItem]?

    // Tags for collections
    @Relationship(deleteRule: .nullify)
    var tags: [Tag]

    init(
        id: UUID = UUID(),
        name: String,
        isStructured: Bool = false,
        createdAt: Date = Date(),
        isStarred: Bool = false,
        tags: [Tag] = []
    ) {
        self.id = id
        self.name = name
        self.isStructured = isStructured
        self.createdAt = createdAt
        self.isStarred = isStarred
        self.tags = tags
    }

    // Helper computed property to get all items sorted by position
    var sortedItems: [CollectionItem] {
        guard let items = collectionItems else { return [] }
        if isStructured {
            return items.sorted { ($0.position ?? Int.max) < ($1.position ?? Int.max) }
        } else {
            // For unstructured lists, sort by creation date of the item
            return items.sorted { item1, item2 in
                guard let date1 = item1.item?.createdAt,
                      let date2 = item2.item?.createdAt else {
                    return false
                }
                return date1 < date2
            }
        }
    }
}
