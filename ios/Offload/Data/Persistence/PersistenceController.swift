// Purpose: SwiftData container and persistence setup.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Avoid side effects outside model context initialization.

//  Registers schema and provides shared/preview containers.

import Foundation
import OSLog
import SwiftData

/// Simplified persistence controller for all SwiftData models
enum PersistenceController {
    private static let appGroupID = "group.wc.Offload"
    private static let storeFilename = "Offload.store"

    /// Shared persistent container for production use.
    /// Prefers the App Group container (so Share Extension and Widget share data with the main app)
    /// but falls back to the default container when the App Group is unavailable (e.g., CI simulators
    /// that lack provisioning for the development team).
    static let shared: ModelContainer = {
        let schema = Schema([
            Item.self,
            Collection.self,
            CollectionItem.self,
            Tag.self,
        ])

        // Attempt App Group container first for extension data sharing.
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            let storeURL = groupURL.appending(path: storeFilename)
            let groupConfig = ModelConfiguration(
                storeFilename,
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                groupContainer: .identifier(appGroupID)
            )
            do {
                let container = try ModelContainer(
                    for: schema,
                    migrationPlan: nil,
                    configurations: [groupConfig]
                )
                AppLogger.persistence.info("ModelContainer created in App Group container - url: \(storeURL.path, privacy: .public)")
                return container
            } catch {
                AppLogger.persistence.error("App Group ModelContainer failed, falling back to default - error: \(error.localizedDescription, privacy: .public)")
            }
        } else {
            AppLogger.persistence.warning("App Group container unavailable (group: \(appGroupID, privacy: .public)), using default container")
        }

        // Fallback: default container (no extension data sharing, but tests and CI still work).
        let fallbackConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: nil,
                configurations: [fallbackConfig]
            )
        } catch {
            AppLogger.persistence.critical("Failed to create fallback ModelContainer: \(error.localizedDescription, privacy: .public)")
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    /// Preview container with sample data for SwiftUI previews
    static let preview: ModelContainer = {
        let schema = Schema([
            Item.self,
            Collection.self,
            CollectionItem.self,
            Tag.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        do {
            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )

            try MainActor.assumeIsolated {
                let context = container.mainContext

                // Insert sample uncategorized items (captures)
                let capture1 = Item(
                    type: nil,
                    content: "Remember to review the quarterly budget analysis"
                )
                let capture2 = Item(
                    type: nil,
                    content: "Call the dentist to schedule appointment for next week"
                )
                let capture3 = Item(
                    type: nil,
                    content: "Buy groceries: milk, eggs, bread, coffee"
                )

                context.insert(capture1)
                context.insert(capture2)
                context.insert(capture3)

                // Insert sample collection (plan)
                let workCollection = Collection(
                    name: "Work Projects",
                    isStructured: true
                )
                context.insert(workCollection)

                // Insert sample categorized items
                let item1 = Item(
                    type: "task",
                    content: "Review Q4 budget - Analyze spending patterns and prepare report",
                    isStarred: true
                )
                let item2 = Item(
                    type: "task",
                    content: "Schedule dentist appointment",
                    completedAt: Date()
                )
                let item3 = Item(
                    type: "task",
                    content: "Remember to backup important files weekly"
                )

                context.insert(item1)
                context.insert(item2)
                context.insert(item3)

                // Link items to collection
                let collectionItem1 = CollectionItem(
                    collectionId: workCollection.id,
                    itemId: item1.id,
                    position: 0
                )
                let collectionItem2 = CollectionItem(
                    collectionId: workCollection.id,
                    itemId: item2.id,
                    position: 1
                )

                context.insert(collectionItem1)
                context.insert(collectionItem2)

                try context.save()
            }

            return container
        } catch {
            AppLogger.persistence.critical("Failed to create preview ModelContainer: \(error.localizedDescription, privacy: .public)")
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }()
}
