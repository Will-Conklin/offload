import SwiftUI
import SwiftData

// AGENT NAV
// - App
// - Scene


@main
struct OffloadApp: App {
    @StateObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(themeManager)
        }
        .modelContainer(PersistenceController.shared)
    }
}
