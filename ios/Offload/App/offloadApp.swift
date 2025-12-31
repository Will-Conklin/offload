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
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(PersistenceController.shared)
    }
}
