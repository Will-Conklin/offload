//
//  AppRootView.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//
//  Intent: Routes the app through the tab shell to expose inbox, organize, and settings.
//

import SwiftUI
import SwiftData

struct AppRootView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    AppRootView()
        .modelContainer(PersistenceController.preview)
}
