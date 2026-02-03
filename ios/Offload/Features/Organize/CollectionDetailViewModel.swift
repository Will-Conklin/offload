// Purpose: Collection detail pagination state.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep view model logic lightweight and MainActor-bound.

import Foundation
import Observation
import OSLog


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
            AppLogger.workflow.info(
                "CollectionDetail setCollection - id: \(id, privacy: .public), isStructured: \(isStructured, privacy: .public)"
            )
            collectionId = id
            self.isStructured = isStructured
            reset()
        }

        if !hasLoaded {
            try loadNextPage(using: repository)
            hasLoaded = true
            AppLogger.workflow.info("CollectionDetail initial load completed - count: \(self.items.count, privacy: .public)")
        }
    }

    func loadNextPage(using repository: CollectionItemRepository) throws {
        guard let collectionId else {
            AppLogger.workflow.debug("CollectionDetail loadNextPage skipped - missing collection")
            return
        }
        guard !isLoading else {
            AppLogger.workflow.debug("CollectionDetail loadNextPage skipped - already loading")
            return
        }
        guard hasMore else {
            AppLogger.workflow.debug("CollectionDetail loadNextPage skipped - no more items")
            return
        }
        isLoading = true
        defer { isLoading = false }

        AppLogger.workflow.debug(
            "CollectionDetail loadNextPage fetching - id: \(collectionId, privacy: .public), offset: \(self.offset, privacy: .public), limit: \(self.pageSize, privacy: .public)"
        )
        do {
            let page = try repository.fetchPage(
                collectionId: collectionId,
                isStructured: isStructured,
                limit: pageSize,
                offset: offset
            )
            items.append(contentsOf: page)
            offset += page.count
            hasMore = page.count == pageSize
            AppLogger.workflow.info(
                "CollectionDetail loadNextPage completed - fetched: \(page.count, privacy: .public), offset: \(self.offset, privacy: .public), hasMore: \(self.hasMore, privacy: .public)"
            )
        } catch {
            AppLogger.workflow.error(
                "CollectionDetail loadNextPage failed - offset: \(self.offset, privacy: .public), error: \(error.localizedDescription, privacy: .public)"
            )
            throw error
        }
    }

    func refresh(using repository: CollectionItemRepository) throws {
        guard collectionId != nil else {
            AppLogger.workflow.debug("CollectionDetail refresh skipped - missing collection")
            return
        }
        AppLogger.workflow.debug("CollectionDetail refresh starting")
        reset()
        try loadNextPage(using: repository)
        hasLoaded = true
        AppLogger.workflow.info("CollectionDetail refresh completed - count: \(self.items.count, privacy: .public)")
    }

    func remove(_ collectionItem: CollectionItem) {
        let originalCount = items.count
        items.removeAll { $0.id == collectionItem.id }
        let removedCount = originalCount - items.count
        if removedCount > 0 {
            offset = max(0, offset - removedCount)
        }
        AppLogger.workflow.debug(
            "CollectionDetail remove completed - removed: \(removedCount, privacy: .public), offset: \(self.offset, privacy: .public)"
        )
    }

    private func reset() {
        items.removeAll()
        offset = 0
        hasMore = true
        hasLoaded = false
        AppLogger.workflow.debug("CollectionDetail reset completed")
    }
}
