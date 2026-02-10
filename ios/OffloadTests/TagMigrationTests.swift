// Purpose: Unit tests for tag migration behavior.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep migrations idempotent and deterministic.

@testable import Offload
import SwiftData
import XCTest

@MainActor
final class TagMigrationTests: XCTestCase {
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!

    override func setUp() async throws {
        let schema = Schema([
            Item.self,
            Collection.self,
            CollectionItem.self,
            Tag.self,
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = modelContainer.mainContext
    }

    override func tearDown() {
        modelContainer = nil
        modelContext = nil
    }

    func testRunIfNeededMigratesLegacyTagsAndClearsLegacyField() throws {
        let item = Item(content: "Legacy item", tags: ["work", "urgent", "  "])
        modelContext.insert(item)
        try modelContext.save()

        try TagMigration.runIfNeeded(modelContext: modelContext)

        XCTAssertTrue(item.legacyTags.isEmpty)
        XCTAssertEqual(item.tags.count, 2)
        XCTAssertEqual(Set(item.tags.map(\.name)), Set(["work", "urgent"]))
    }

    func testRunIfNeededDeduplicatesEquivalentTagsAndRebindsRelationships() throws {
        let canonical = Tag(name: "Work")
        let duplicate = Tag(name: " work ")
        modelContext.insert(canonical)
        modelContext.insert(duplicate)

        let directItem = Item(content: "Direct tag item")
        directItem.tags = [duplicate]
        modelContext.insert(directItem)

        let legacyItem = Item(content: "Legacy tag item", tags: ["WORK"])
        modelContext.insert(legacyItem)

        let collection = Collection(name: "Tagged Collection")
        collection.tags = [duplicate]
        modelContext.insert(collection)

        try modelContext.save()

        try TagMigration.runIfNeeded(modelContext: modelContext)

        let allTags = try modelContext.fetch(FetchDescriptor<Tag>())
        XCTAssertEqual(allTags.count, 1)
        let mergedTag = try XCTUnwrap(allTags.first)
        XCTAssertEqual(mergedTag.name, "Work")

        XCTAssertEqual(directItem.tags.count, 1)
        XCTAssertEqual(directItem.tags.first?.id, mergedTag.id)

        XCTAssertEqual(legacyItem.tags.count, 1)
        XCTAssertEqual(legacyItem.tags.first?.id, mergedTag.id)
        XCTAssertTrue(legacyItem.legacyTags.isEmpty)

        XCTAssertEqual(collection.tags.count, 1)
        XCTAssertEqual(collection.tags.first?.id, mergedTag.id)
    }
}
