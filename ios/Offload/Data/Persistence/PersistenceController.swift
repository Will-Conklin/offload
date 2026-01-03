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
            // Destination models
            Plan.self,
            Task.self,
            Tag.self,
            Category.self,
            ListEntity.self,
            ListItem.self,
            CommunicationItem.self,
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
            // Destination models
            Plan.self,
            Task.self,
            Tag.self,
            Category.self,
            ListEntity.self,
            ListItem.self,
            CommunicationItem.self,
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

            let context = MainActor.assumeIsolated {
                container.mainContext
            }

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

            // Insert sample plan
            let workPlan = Plan(
                title: "Work Projects",
                detail: "Active work-related projects"
            )
            context.insert(workPlan)

            // Insert sample tasks
            let task1 = Task(
                title: "Review Q4 budget",
                detail: "Analyze spending patterns and prepare report",
                importance: 4,
                plan: workPlan
            )
            let task2 = Task(
                title: "Schedule dentist appointment",
                isDone: true,
                importance: 3
            )

            context.insert(task1)
            context.insert(task2)

            try context.save()

            return container
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }()
}
