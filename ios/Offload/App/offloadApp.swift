// Purpose: App entry points and root navigation.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep navigation flow consistent with MainTabView -> NavigationStack -> sheets.

import SwiftUI
import SwiftData
import OSLog



@main
struct OffloadApp: App {
    @StateObject private var themeManager = ThemeManager.shared

    init() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        AppLogger.general.info("App launch - version: \(version, privacy: .public) (\(build, privacy: .public))")
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(themeManager)
        }
        .modelContainer(PersistenceController.shared)
    }
}
