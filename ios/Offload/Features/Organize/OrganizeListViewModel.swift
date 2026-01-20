// Purpose: Organize feature pagination state.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep view model logic lightweight and MainActor-bound.

import Foundation
import Observation


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
            currentScopeIsStructured = isStructured
            reset()
        }

        if !hasLoaded {
            try loadNextPage(using: repository)
            hasLoaded = true
        }
    }

    func loadNextPage(using repository: CollectionRepository) throws {
        guard let currentScopeIsStructured else { return }
        guard !isLoading, hasMore else { return }
        isLoading = true
        defer { isLoading = false }

        let page = try repository.fetchPage(
            isStructured: currentScopeIsStructured,
            limit: pageSize,
            offset: offset
        )
        collections.append(contentsOf: page)
        offset += page.count
        hasMore = page.count == pageSize
    }

    func refresh(using repository: CollectionRepository) throws {
        guard currentScopeIsStructured != nil else { return }
        reset()
        try loadNextPage(using: repository)
        hasLoaded = true
    }

    private func reset() {
        collections.removeAll()
        offset = 0
        hasMore = true
        hasLoaded = false
    }
}
