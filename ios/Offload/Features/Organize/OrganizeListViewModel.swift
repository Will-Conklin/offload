// Purpose: Organize feature pagination state.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep view model logic lightweight and MainActor-bound.

import Foundation
import Observation
import OSLog

@Observable
@MainActor
final class OrganizeListViewModel {
    private(set) var collections: [Collection] = []
    private(set) var isLoading = false
    private(set) var hasMore = true
    private(set) var hasLoaded = false

    private let pageSize = 50
    private var offset = 0
    private var currentScopeIsStructured: Bool?

    func setScope(isStructured: Bool, using repository: CollectionRepository) throws {
        if currentScopeIsStructured != isStructured {
            AppLogger.workflow.info("OrganizeList scope changed - isStructured: \(isStructured, privacy: .public)")
            currentScopeIsStructured = isStructured
            reset()
        }

        if !hasLoaded {
            try loadNextPage(using: repository)
            hasLoaded = true
            AppLogger.workflow.info("OrganizeList initial load completed - count: \(self.collections.count, privacy: .public)")
        }
    }

    func loadNextPage(using repository: CollectionRepository) throws {
        guard let currentScopeIsStructured else {
            AppLogger.workflow.debug("OrganizeList loadNextPage skipped - scope not set")
            return
        }
        guard !isLoading else {
            AppLogger.workflow.debug("OrganizeList loadNextPage skipped - already loading")
            return
        }
        guard hasMore else {
            AppLogger.workflow.debug("OrganizeList loadNextPage skipped - no more collections")
            return
        }
        isLoading = true
        defer { isLoading = false }

        AppLogger.workflow.debug(
            "OrganizeList loadNextPage fetching - isStructured: \(currentScopeIsStructured, privacy: .public), offset: \(self.offset, privacy: .public), limit: \(self.pageSize, privacy: .public)"
        )
        do {
            let page = try repository.fetchPage(
                isStructured: currentScopeIsStructured,
                limit: pageSize,
                offset: offset
            )
            collections.append(contentsOf: page)
            offset += page.count
            hasMore = page.count == pageSize
            AppLogger.workflow.info(
                "OrganizeList loadNextPage completed - fetched: \(page.count, privacy: .public), offset: \(self.offset, privacy: .public), hasMore: \(self.hasMore, privacy: .public)"
            )
        } catch {
            AppLogger.workflow.error(
                "OrganizeList loadNextPage failed - offset: \(self.offset, privacy: .public), error: \(error.localizedDescription, privacy: .public)"
            )
            throw error
        }
    }

    func refresh(using repository: CollectionRepository) throws {
        guard currentScopeIsStructured != nil else {
            AppLogger.workflow.debug("OrganizeList refresh skipped - scope not set")
            return
        }
        AppLogger.workflow.debug("OrganizeList refresh starting")
        reset()
        try loadNextPage(using: repository)
        hasLoaded = true
        AppLogger.workflow.info("OrganizeList refresh completed - count: \(self.collections.count, privacy: .public)")
    }

    private func reset() {
        collections.removeAll()
        offset = 0
        hasMore = true
        hasLoaded = false
        AppLogger.workflow.debug("OrganizeList reset completed")
    }
}
