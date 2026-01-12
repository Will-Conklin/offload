//
//  PersistenceController.swift
//  Offload
//
//  Created by Claude Code on 12/31/25.
//
//  Intent: Central SwiftData configuration for all models.
//  Registers schema and provides shared/preview containers.
//

import Foundation
import SwiftData

/// Simplified persistence controller for all SwiftData models
struct PersistenceController {

    /// Shared persistent container for production use
    static let shared: ModelContainer = {
        let schema = Schema([
            // Core workflow models
            CaptureEntry.self,
            HandOffRequest.self,
            HandOffRun.self,
            Suggestion.self,
            SuggestionDecision.self,
            Placement.self,
            // Simplified data models
            Item.self,
            Collection.self,
            CollectionItem.self,
            Tag.self,
            Category.self,
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    /// Preview container with sample data for SwiftUI previews
    static let preview: ModelContainer = {
        let schema = Schema([
            // Core workflow models
            CaptureEntry.self,
            HandOffRequest.self,
            HandOffRun.self,
            Suggestion.self,
            SuggestionDecision.self,
            Placement.self,
            // Simplified data models
            Item.self,
            Collection.self,
            CollectionItem.self,
            Tag.self,
            Category.self,
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

                // Insert sample thought captures
                let sampleEntries = [
                    CaptureEntry(
                        rawText: "Remember to review the quarterly budget analysis",
                        inputType: .text,
                        source: .app
                    ),
                    CaptureEntry(
                        rawText: "Call the dentist to schedule appointment for next week",
                        inputType: .voice,
                        source: .app
                    ),
                    CaptureEntry(
                        rawText: "Research SwiftData best practices for production apps",
                        inputType: .text,
                        source: .app,
                        lifecycleState: .handedOff
                    ),
                    CaptureEntry(
                        rawText: "Buy groceries: milk, eggs, bread, coffee",
                        inputType: .voice,
                        source: .widget,
                        lifecycleState: .ready
                    ),
                ]

                for entry in sampleEntries {
                    context.insert(entry)
                }

                // Insert sample collection (plan)
                let workCollection = Collection(
                    name: "Work Projects",
                    isStructured: true
                )
                context.insert(workCollection)

                // Insert sample items
                let item1 = Item(
                    type: "task",
                    content: "Review Q4 budget - Analyze spending patterns and prepare report",
                    isStarred: true
                )
                let item2 = Item(
                    type: "task",
                    content: "Schedule dentist appointment"
                )
                let item3 = Item(
                    type: "note",
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
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }()
}
