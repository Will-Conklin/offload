// Purpose: Environment keys for repository dependency injection.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: All views should access repositories through environment, not create them directly.

import OSLog
import SwiftData
import SwiftUI

// MARK: - Environment Keys

private struct ItemRepositoryKey: EnvironmentKey {
    static let defaultValue: ItemRepository? = nil
}

private struct CollectionRepositoryKey: EnvironmentKey {
    static let defaultValue: CollectionRepository? = nil
}

private struct CollectionItemRepositoryKey: EnvironmentKey {
    static let defaultValue: CollectionItemRepository? = nil
}

private struct TagRepositoryKey: EnvironmentKey {
    static let defaultValue: TagRepository? = nil
}

// MARK: - Environment Values Extension

extension EnvironmentValues {
    var itemRepository: ItemRepository {
        get {
            if let repository = self[ItemRepositoryKey.self] {
                return repository
            }
            AppLogger.general.error("ItemRepository not injected; falling back to modelContext.")
            return MainActor.assumeIsolated {
                ItemRepository(modelContext: modelContext)
            }
        }
        set { self[ItemRepositoryKey.self] = newValue }
    }

    var collectionRepository: CollectionRepository {
        get {
            if let repository = self[CollectionRepositoryKey.self] {
                return repository
            }
            AppLogger.general.error("CollectionRepository not injected; falling back to modelContext.")
            return MainActor.assumeIsolated {
                CollectionRepository(modelContext: modelContext)
            }
        }
        set { self[CollectionRepositoryKey.self] = newValue }
    }

    var collectionItemRepository: CollectionItemRepository {
        get {
            if let repository = self[CollectionItemRepositoryKey.self] {
                return repository
            }
            AppLogger.general.error("CollectionItemRepository not injected; falling back to modelContext.")
            return MainActor.assumeIsolated {
                CollectionItemRepository(modelContext: modelContext)
            }
        }
        set { self[CollectionItemRepositoryKey.self] = newValue }
    }

    var tagRepository: TagRepository {
        get {
            if let repository = self[TagRepositoryKey.self] {
                return repository
            }
            AppLogger.general.error("TagRepository not injected; falling back to modelContext.")
            return MainActor.assumeIsolated {
                TagRepository(modelContext: modelContext)
            }
        }
        set { self[TagRepositoryKey.self] = newValue }
    }
}

// MARK: - Repository Factory

@MainActor
struct RepositoryBundle {
    let itemRepository: ItemRepository
    let collectionRepository: CollectionRepository
    let collectionItemRepository: CollectionItemRepository
    let tagRepository: TagRepository

    static func make(modelContext: ModelContext) -> RepositoryBundle {
        RepositoryBundle(
            itemRepository: ItemRepository(modelContext: modelContext),
            collectionRepository: CollectionRepository(modelContext: modelContext),
            collectionItemRepository: CollectionItemRepository(modelContext: modelContext),
            tagRepository: TagRepository(modelContext: modelContext)
        )
    }

    #if DEBUG
        static func preview(from container: ModelContainer) -> RepositoryBundle {
            make(modelContext: container.mainContext)
        }
    #endif
}

// MARK: - Preview Helpers

#if DEBUG
    extension EnvironmentValues {
        /// Create repositories from a preview ModelContainer
        @MainActor
        static func previewRepositories(from container: ModelContainer) -> (
            itemRepository: ItemRepository,
            collectionRepository: CollectionRepository,
            collectionItemRepository: CollectionItemRepository,
            tagRepository: TagRepository
        ) {
            let repositories = RepositoryBundle.preview(from: container)
            return (
                itemRepository: repositories.itemRepository,
                collectionRepository: repositories.collectionRepository,
                collectionItemRepository: repositories.collectionItemRepository,
                tagRepository: repositories.tagRepository
            )
        }
    }
#endif
