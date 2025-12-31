import SwiftData
import SwiftUI

@main
struct OffloadApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(PersistenceController.shared)
    }
}
