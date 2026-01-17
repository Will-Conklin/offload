import SwiftUI
import SwiftData

// AGENT NAV
// - View
// - Preview


struct AppRootView: View {

    var body: some View {
        MainTabView()
    }
}

#Preview {
    AppRootView()
        .environmentObject(ThemeManager.shared)
        .modelContainer(PersistenceController.preview)
}
