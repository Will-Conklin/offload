// Purpose: Collection detail pagination state.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep view model logic lightweight and MainActor-bound.

import Foundation
import Observation


@Observable
@MainActor
final class CollectionDetailViewModel {
    private(set) var items: [CollectionItem] = []
    private(set) var isLoading = false
    private(set) var hasMore = true
    private(set) var hasLoaded = false

    private let pageSize = 50
    private var offset = 0
    private var collectionId: UUID?
    private var isStructured = false

    func setCollection(
        id: UUID,
        isStructured: Bool,
        using repository: CollectionItemRepository
    ) throws {
        if collectionId != id || self.isStructured != isStructured {
            collectionId = id
            self.isStructured = isStructured
            reset()
        }

        if !hasLoaded {
            try loadNextPage(using: repository)
            hasLoaded = true
        }
    }

    func loadNextPage(using repository: CollectionItemRepository) throws {
        guard let collectionId else { return }
        guard !isLoading, hasMore else { return }
        isLoading = true
        defer { isLoading = false }

        let page = try repository.fetchPage(
            collectionId: collectionId,
            isStructured: isStructured,
            limit: pageSize,
            offset: offset
        )
        items.append(contentsOf: page)
        offset += page.count
        hasMore = page.count == pageSize
    }

    func refresh(using repository: CollectionItemRepository) throws {
        guard collectionId != nil else { return }
        reset()
        try loadNextPage(using: repository)
        hasLoaded = true
    }

    func remove(_ collectionItem: CollectionItem) {
        let originalCount = items.count
        items.removeAll { $0.id == collectionItem.id }
        let removedCount = originalCount - items.count
        if removedCount > 0 {
            offset = max(0, offset - removedCount)
        }
    }

    private func reset() {
        items.removeAll()
        offset = 0
        hasMore = true
        hasLoaded = false
    }
}
