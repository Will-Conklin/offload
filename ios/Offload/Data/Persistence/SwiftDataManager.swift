//
//  SwiftDataManager.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import Foundation
import SwiftData

/// Manages SwiftData model container configuration and setup
final class SwiftDataManager {
    static let shared = SwiftDataManager()

    private init() {}

    // TODO: Add migration strategies
    // TODO: Add backup/restore functionality
    // TODO: Add data export functionality
    // TODO: Add CloudKit sync configuration

    func createModelContainer() throws -> ModelContainer {
        let schema = Schema([
            // Core workflow models
            CaptureEntry.self,
            HandOffRequest.self,
            HandOffRun.self,
            Suggestion.self,
            SuggestionDecision.self,
            Placement.self,
            // Destination models
            Plan.self,
            Task.self,
            Tag.self,
            Category.self,
            ListEntity.self,
            ListItem.self,
            CommunicationItem.self,
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
            // TODO: Add CloudKit container configuration
            // TODO: Add groupContainer for app groups/widgets
        )

        return try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
    }
}
