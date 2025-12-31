import SwiftData
import SwiftUI

struct AppRootView: View {
    var body: some View {
        NavigationStack {
            InboxView()
        }
    }
}

#Preview {
    AppRootView()
        .modelContainer(PersistenceController.preview)
}
