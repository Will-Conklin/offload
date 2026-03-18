// Purpose: App entry points and root navigation.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Keep navigation flow consistent with MainTabView -> NavigationStack -> sheets.

import os
import SwiftData
import SwiftUI
import UIKit

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var authManager: AuthManager
    @State private var repositories: RepositoryBundle?
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    private let launchCorrelationId = UUID().uuidString

    var body: some View {
        MainTabView()
            .environment(\.itemRepository, repositories?.itemRepository ?? ItemRepository(modelContext: modelContext))
            .environment(\.collectionRepository, repositories?.collectionRepository ?? CollectionRepository(modelContext: modelContext))
            .environment(\.collectionItemRepository, repositories?.collectionItemRepository ?? CollectionItemRepository(modelContext: modelContext))
            .environment(\.tagRepository, repositories?.tagRepository ?? TagRepository(modelContext: modelContext))
            .preferredColorScheme(themeManager.appearancePreference.colorScheme)
            .withToast()
            .sheet(isPresented: Binding(
                get: { !hasCompletedOnboarding },
                set: { showSheet in if !showSheet { hasCompletedOnboarding = true } }
            )) {
                OnboardingView(onComplete: { hasCompletedOnboarding = true })
                    .environmentObject(themeManager)
                    .environmentObject(authManager)
            }
            .task {
                let startupStart = Date()
                let memoryBeforeStartup = MemoryDiagnostics.residentMemoryBytes()
                AppLogger.general.info(
                    "Startup diagnostics begin - launchId: \(self.launchCorrelationId, privacy: .public), memory: \(MemoryDiagnostics.residentMemoryMBString(), privacy: .public)"
                )

                if repositories == nil {
                    repositories = RepositoryBundle.make(modelContext: modelContext)
                    AppLogger.general.info("Repository bundle initialized")
                }

                // Flush any captures queued by the Share Extension or App Intents
                if let repos = repositories {
                    QuickCaptureService(itemRepository: repos.itemRepository).flushPending()
                }

                let startupDuration = Date().timeIntervalSince(startupStart)
                let memoryAfterStartup = MemoryDiagnostics.residentMemoryBytes()
                AppLogger.general.info(
                    "Startup diagnostics end - launchId: \(self.launchCorrelationId, privacy: .public), durationMs: \(Int((startupDuration * 1000).rounded()), privacy: .public), memoryAfter: \(MemoryDiagnostics.residentMemoryMBString(), privacy: .public), memoryDelta: \(MemoryDiagnostics.deltaMBString(before: memoryBeforeStartup, after: memoryAfterStartup), privacy: .public)"
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                if let repos = repositories {
                    QuickCaptureService(itemRepository: repos.itemRepository).flushPending()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                let timestamp = Date().ISO8601Format()
                AppLogger.general.warning(
                    "Memory warning received - launchId: \(self.launchCorrelationId, privacy: .public), timestamp: \(timestamp, privacy: .public), residentMemory: \(MemoryDiagnostics.residentMemoryMBString(), privacy: .public)"
                )
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
