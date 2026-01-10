//
//  AppRootView.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import SwiftUI
import SwiftData

struct AppRootView: View {
    @StateObject private var themeManager = ThemeManager.shared

    var body: some View {
        MainTabView()
            .environmentObject(themeManager)
    }
}

#Preview {
    AppRootView()
        .modelContainer(PersistenceController.preview)
}
