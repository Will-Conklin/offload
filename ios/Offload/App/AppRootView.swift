// Purpose: App entry points and root navigation.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep navigation flow consistent with MainTabView -> NavigationStack -> sheets.

import SwiftUI
import SwiftData
import os



struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var didLogRepositories = false

    var body: some View {
        let repositories = RepositoryBundle.make(modelContext: modelContext)

        MainTabView()
            .environment(\.itemRepository, repositories.itemRepository)
            .environment(\.collectionRepository, repositories.collectionRepository)
            .environment(\.collectionItemRepository, repositories.collectionItemRepository)
            .environment(\.tagRepository, repositories.tagRepository)
            .preferredColorScheme(themeManager.appearancePreference.colorScheme)
            .withToast()
            .task {
                if !didLogRepositories {
                    AppLogger.general.info("Repository bundle initialized")
                    didLogRepositories = true
                }
                do {
                    try TagMigration.runIfNeeded(modelContext: modelContext)
                } catch {
                    AppLogger.general.error("Tag migration failed: \(error.localizedDescription)")
                }
            }
    }
}

#Preview {
    let container = PersistenceController.preview
    let repos = RepositoryBundle.preview(from: container)

    return AppRootView()
        .environmentObject(ThemeManager.shared)
        .modelContainer(container)
        .environment(\.itemRepository, repos.itemRepository)
        .environment(\.collectionRepository, repos.collectionRepository)
        .environment(\.collectionItemRepository, repos.collectionItemRepository)
        .environment(\.tagRepository, repos.tagRepository)
}
