// Purpose: Capture feature pagination state.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep view model logic lightweight and MainActor-bound.

import Foundation
import Observation
import OSLog

@Observable
@MainActor
final class CaptureListViewModel {
    private(set) var items: [Item] = []
    private(set) var isLoading = false
    private(set) var hasMore = true
    private(set) var hasLoaded = false

    private let pageSize = 50
    private var offset = 0

    func loadInitial(using repository: ItemRepository) throws {
        AppLogger.workflow.debug("CaptureList loadInitial starting")
        reset()
        try loadNextPage(using: repository)
        hasLoaded = true
        AppLogger.workflow.info("CaptureList loadInitial completed - count: \(items.count, privacy: .public)")
    }

    func loadNextPage(using repository: ItemRepository) throws {
        guard !isLoading else {
            AppLogger.workflow.debug("CaptureList loadNextPage skipped - already loading")
            return
        }
        guard hasMore else {
            AppLogger.workflow.debug("CaptureList loadNextPage skipped - no more items")
            return
        }
        isLoading = true
        defer { isLoading = false }

        AppLogger.workflow.debug("CaptureList loadNextPage fetching - offset: \(offset, privacy: .public), limit: \(pageSize, privacy: .public)")
        do {
            let page = try repository.fetchCaptureItems(limit: pageSize, offset: offset)
            items.append(contentsOf: page)
            offset += page.count
            hasMore = page.count == pageSize
            AppLogger.workflow.info(
                "CaptureList loadNextPage completed - fetched: \(page.count, privacy: .public), offset: \(offset, privacy: .public), hasMore: \(hasMore, privacy: .public)"
            )
        } catch {
            AppLogger.workflow.error(
                "CaptureList loadNextPage failed - offset: \(offset, privacy: .public), error: \(error.localizedDescription, privacy: .public)"
            )
            throw error
        }
    }

    func refresh(using repository: ItemRepository) throws {
        AppLogger.workflow.debug("CaptureList refresh starting")
        reset()
        try loadNextPage(using: repository)
        hasLoaded = true
        AppLogger.workflow.info("CaptureList refresh completed - count: \(items.count, privacy: .public)")
    }

    func remove(_ item: Item) {
        let originalCount = items.count
        items.removeAll { $0.id == item.id }
        let removedCount = originalCount - items.count
        if removedCount > 0 {
            offset = max(0, offset - removedCount)
        }
        AppLogger.workflow.debug(
            "CaptureList remove completed - removed: \(removedCount, privacy: .public), offset: \(offset, privacy: .public)"
        )
    }

    private func reset() {
        items.removeAll()
        offset = 0
        hasMore = true
        hasLoaded = false
        AppLogger.workflow.debug("CaptureList reset completed")
    }
}
