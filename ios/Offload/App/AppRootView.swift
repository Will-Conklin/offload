//
//  AppRootView.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
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
        .environmentObject(ThemeManager.shared)
        .modelContainer(PersistenceController.preview)
}
