// Purpose: Capture feature pagination state.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep view model logic lightweight and MainActor-bound.

import Foundation
import Observation


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
        reset()
        try loadNextPage(using: repository)
        hasLoaded = true
    }

    func loadNextPage(using repository: ItemRepository) throws {
        guard !isLoading, hasMore else { return }
        isLoading = true
        defer { isLoading = false }

        let page = try repository.fetchCaptureItems(limit: pageSize, offset: offset)
        items.append(contentsOf: page)
        offset += page.count
        hasMore = page.count == pageSize
    }

    func refresh(using repository: ItemRepository) throws {
        reset()
        try loadNextPage(using: repository)
        hasLoaded = true
    }

    func remove(_ item: Item) {
        let originalCount = items.count
        items.removeAll { $0.id == item.id }
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
