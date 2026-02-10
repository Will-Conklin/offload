// Purpose: Data migrations for evolving the SwiftData model.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep migrations idempotent and MainActor-safe.

import Foundation
import SwiftData

@MainActor
struct TagMigration {
    static func runIfNeeded(modelContext: ModelContext) throws {
        var didChange = false
        var canonicalTagsByName = try buildCanonicalTagLookup(
            in: modelContext,
            didChange: &didChange
        )

        let itemDescriptor = FetchDescriptor<Item>()
        let items = try modelContext.fetch(itemDescriptor)

        for item in items {
            guard !item.legacyTags.isEmpty else { continue }
            for legacyName in item.legacyTags {
                let trimmed = legacyName.trimmingCharacters(in: .whitespacesAndNewlines)
                let normalized = Tag.normalizedName(trimmed)
                guard !normalized.isEmpty else { continue }

                let tag: Tag
                if let existing = canonicalTagsByName[normalized] {
                    tag = existing
                } else {
                    let created = Tag(name: trimmed)
                    modelContext.insert(created)
                    canonicalTagsByName[normalized] = created
                    didChange = true
                    tag = created
                }

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

    private static func buildCanonicalTagLookup(
        in modelContext: ModelContext,
        didChange: inout Bool
    ) throws -> [String: Tag] {
        let descriptor = FetchDescriptor<Tag>(
            sortBy: [SortDescriptor(\.createdAt)]
        )
        let tags = try modelContext.fetch(descriptor)

        var canonicalByName: [String: Tag] = [:]
        var duplicates: [Tag] = []

        for tag in tags {
            let trimmed = tag.name.trimmingCharacters(in: .whitespacesAndNewlines)
            if tag.name != trimmed {
                tag.name = trimmed
                didChange = true
            }

            let normalized = Tag.normalizedName(trimmed)
            guard !normalized.isEmpty else { continue }

            if let canonical = canonicalByName[normalized] {
                mergeRelationships(from: tag, into: canonical)
                duplicates.append(tag)
                didChange = true
            } else {
                canonicalByName[normalized] = tag
            }
        }

        for duplicate in duplicates {
            modelContext.delete(duplicate)
        }

        return canonicalByName
    }

    private static func mergeRelationships(from duplicate: Tag, into canonical: Tag) {
        for item in duplicate.items where !item.tags.contains(where: { $0.id == canonical.id }) {
            item.tags.append(canonical)
        }
        for collection in duplicate.collections where !collection.tags.contains(where: { $0.id == canonical.id }) {
            collection.tags.append(canonical)
        }
    }

}
