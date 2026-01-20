// Purpose: Performance benchmarks for repository queries.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep tests deterministic and avoid relying on network or time.

import XCTest
import SwiftData
@testable import Offload


@MainActor
final class PerformanceBenchmarkTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Item.self,
            Collection.self,
            CollectionItem.self,
            Tag.self,
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func seedItems(count: Int, modelContext: ModelContext) throws {
        guard count > 0 else { return }
        for index in 0..<count {
            let item = Item(content: "Item \(index)")
            modelContext.insert(item)
        }
        try modelContext.save()
    }

    private func benchmarkFetchAll(count: Int) throws {
        let container = try makeContainer()
        let context = container.mainContext
        let repository = ItemRepository(modelContext: context)
        try seedItems(count: count, modelContext: context)

        let options = XCTMeasureOptions()
        options.iterationCount = 3
        measure(metrics: [XCTClockMetric()], options: options) {
            XCTAssertNoThrow(try repository.fetchAll())
        }
    }

    func testFetchAllPerformance100Items() throws {
        try benchmarkFetchAll(count: 100)
    }

    func testFetchAllPerformance1000Items() throws {
        try benchmarkFetchAll(count: 1_000)
    }

    func testFetchAllPerformance10000Items() throws {
        try benchmarkFetchAll(count: 10_000)
    }
}
