// Purpose: Data migrations for evolving the SwiftData model.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep migrations idempotent and MainActor-safe.

import Foundation
import SwiftData


@MainActor
struct TagMigration {
    static func runIfNeeded(modelContext: ModelContext) throws {
        let descriptor = FetchDescriptor<Item>()
        let items = try modelContext.fetch(descriptor)
        var didChange = false

        for item in items {
            guard !item.legacyTags.isEmpty else { continue }
            for legacyName in item.legacyTags {
                let trimmed = legacyName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }

                let tag = try fetchOrCreateTag(named: trimmed, in: modelContext)
                if !item.tags.contains(where: { $0.id == tag.id }) {
                    item.tags.append(tag)
                    didChange = true
                }
            }

            if !item.legacyTags.isEmpty {
                item.legacyTags = []
                didChange = true
            }
        }

        if didChange {
            try modelContext.save()
        }
    }

    private static func fetchOrCreateTag(named name: String, in modelContext: ModelContext) throws -> Tag {
        let descriptor = FetchDescriptor<Tag>(
            predicate: #Predicate { $0.name == name }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }

        let tag = Tag(name: name)
        modelContext.insert(tag)
        return tag
    }
}
