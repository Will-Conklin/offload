// Purpose: Shared reorder position mapping helper for collection-item links.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Keep reorder behavior stable while avoiding repeated linear scans.

import Foundation

enum ReorderPositionMapper {
    /// Builds a lookup table keyed by `itemId` for fast reorder position assignment.
    /// - Parameter collectionItems: Collection-item links to index.
    /// - Returns: Dictionary of first-seen collection item link per `itemId`.
    static func indexByItemId(_ collectionItems: [CollectionItem]) -> [UUID: CollectionItem] {
        var index: [UUID: CollectionItem] = [:]
        index.reserveCapacity(collectionItems.count)
        for collectionItem in collectionItems where index[collectionItem.itemId] == nil {
            index[collectionItem.itemId] = collectionItem
        }
        return index
    }

    /// Applies contiguous positions to indexed collection-item links in provided order.
    /// - Parameters:
    ///   - orderedItemIds: Item identifiers in desired order.
    ///   - indexedByItemId: Index of collection-item links keyed by `itemId`.
    static func applyPositions(
        for orderedItemIds: [UUID],
        using indexedByItemId: [UUID: CollectionItem]
    ) {
        for (position, itemId) in orderedItemIds.enumerated() {
            indexedByItemId[itemId]?.position = position
        }
    }
}
