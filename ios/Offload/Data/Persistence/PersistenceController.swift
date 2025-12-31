//
//  PersistenceController.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import Foundation
import SwiftData

/// Simplified persistence controller for all SwiftData models
struct PersistenceController {

    /// Shared persistent container for production use
    static let shared: ModelContainer = {
        let schema = Schema([
            Item.self,
            Task.self,
            Project.self,
            Tag.self,
            Category.self,
            Thought.self,
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
            Item.self,
            Task.self,
            Project.self,
            Tag.self,
            Category.self,
            Thought.self,
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

            let context = container.mainContext

            // Insert sample thoughts
            let sampleThoughts = [
                Thought(
                    source: .manual,
                    rawText: "Remember to review the quarterly budget analysis"
                ),
                Thought(
                    source: .voice,
                    rawText: "Call the dentist to schedule appointment for next week"
                ),
                Thought(
                    source: .clipboard,
                    rawText: "Research SwiftData best practices for production apps",
                    status: .processing
                ),
                Thought(
                    source: .share,
                    rawText: "Check out the new design system documentation",
                    status: .processed
                ),
                Thought(
                    source: .widget,
                    rawText: "Buy groceries: milk, eggs, bread, coffee"
                ),
            ]

            for thought in sampleThoughts {
                context.insert(thought)
            }

            try context.save()

            return container
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }()
}
