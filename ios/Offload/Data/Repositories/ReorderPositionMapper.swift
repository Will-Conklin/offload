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

    // MARK: - Shared Sorting

    /// Sorts collection items by position (nil last), then createdAt, then ID for stability.
    static func sortedCollectionItems(_ items: [CollectionItem]) -> [CollectionItem] {
        items.sorted { lhs, rhs in
            let lhsPosition = lhs.position ?? Int.max
            let rhsPosition = rhs.position ?? Int.max
            if lhsPosition != rhsPosition {
                return lhsPosition < rhsPosition
            }
            let lhsDate = lhs.item?.createdAt ?? .distantFuture
            let rhsDate = rhs.item?.createdAt ?? .distantFuture
            if lhsDate != rhsDate {
                return lhsDate < rhsDate
            }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    /// Sorts collections by position (nil last), then createdAt descending.
    static func sortedCollections(_ collections: [Collection]) -> [Collection] {
        collections.sorted { c1, c2 in
            if let p1 = c1.position, let p2 = c2.position {
                p1 < p2
            } else if c1.position != nil {
                true
            } else if c2.position != nil {
                false
            } else {
                c1.createdAt > c2.createdAt
            }
        }
    }

    /// Reassigns contiguous 0-based positions to siblings after a deletion.
    static func compactPositions(_ siblings: [CollectionItem]) {
        let ordered = sortedCollectionItems(siblings)
        for (index, sibling) in ordered.enumerated() {
            sibling.position = index
        }
    }
}
