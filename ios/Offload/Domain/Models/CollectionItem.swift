// Purpose: SwiftData model definitions.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Maintain explicit type references in predicates and preserve relationship rules.

import Foundation
import SwiftData

@Model
final class CollectionItem {
    var id: UUID
    var collectionId: UUID
    var itemId: UUID
    var position: Int? // nullable, ignored when collection.isStructured=false
    var parentId: UUID? // nullable, creates hierarchy in structured collections

    // Relationships
    var collection: Collection?
    var item: Item?

    init(
        id: UUID = UUID(),
        collectionId: UUID,
        itemId: UUID,
        position: Int? = nil,
        parentId: UUID? = nil
    ) {
        self.id = id
        self.collectionId = collectionId
        self.itemId = itemId
        self.position = position
        self.parentId = parentId
    }

    // Helper to check if this is a root item (no parent)
    var isRoot: Bool {
        parentId == nil
    }

    // Helper to check if this has children
    func hasChildren(in context: ModelContext) -> Bool {
        let parentId: UUID? = id
        let descriptor = FetchDescriptor<CollectionItem>(
            predicate: #Predicate<CollectionItem> { item in
                item.parentId == parentId
            }
        )
        let children = (try? context.fetch(descriptor)) ?? []
        return !children.isEmpty
    }
}
