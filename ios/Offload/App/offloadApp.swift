//
//  offloadApp.swift
//  Offload
//
//  Created by William Conklin on 12/30/25.
//

import SwiftUI
import SwiftData

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
