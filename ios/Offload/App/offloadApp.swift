//
//  offloadApp.swift
//  Offload
//
//  Created by William Conklin on 12/30/25.
//
//  Intent: Application entry point injecting the shared model container.
//

import SwiftUI
import SwiftData

@main
struct OffloadApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(PersistenceController.shared)
    }
}
