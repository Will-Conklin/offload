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
    /// Stored in the App Group container so the Share Extension and Widget can enqueue captures.
    static let shared: ModelContainer = {
        let schema = Schema([
            Item.self,
            Collection.self,
            CollectionItem.self,
            Tag.self,
        ])

        let configuration = ModelConfiguration(
            storeFilename,
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .identifier(appGroupID)
        )

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: nil,
                configurations: [configuration]
            )
        } catch {
            AppLogger.persistence.critical("Failed to create production ModelContainer: \(error.localizedDescription, privacy: .public)")
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
