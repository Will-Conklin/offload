// Purpose: Performance benchmarks for repository queries.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep tests deterministic and avoid relying on network or time.

@testable import Offload
import SwiftData
import XCTest

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

    private func seedItems(
        count: Int,
        modelContext: ModelContext,
        configure: ((Item, Int) -> Void)? = nil
    ) throws {
        guard count > 0 else { return }
        for index in 0 ..< count {
            let item = Item(content: "Item \(index)")
            configure?(item, index)
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
            do {
                _ = try repository.fetchAll()
            } catch {
                XCTFail("fetchAll failed: \(error)")
            }
        }
    }

    private func benchmarkFetchCaptureItems(count: Int) throws {
        let container = try makeContainer()
        let context = container.mainContext
        let repository = ItemRepository(modelContext: context)
        let completedAt = Date(timeIntervalSince1970: 0)
        try seedItems(count: count, modelContext: context) { item, index in
            if index.isMultiple(of: 2) {
                item.type = "task"
            }
            if index.isMultiple(of: 10) {
                item.completedAt = completedAt
            }
        }

        let options = XCTMeasureOptions()
        options.iterationCount = 3
        measure(metrics: [XCTClockMetric()], options: options) {
            do {
                _ = try repository.fetchCaptureItems()
            } catch {
                XCTFail("fetchCaptureItems failed: \(error)")
            }
        }
    }

    private func benchmarkFetchByTag(count: Int, tag: String) throws {
        let container = try makeContainer()
        let context = container.mainContext
        let repository = ItemRepository(modelContext: context)
        let targetTag = Tag(name: tag)
        let otherTag = Tag(name: "other")
        context.insert(targetTag)
        context.insert(otherTag)
        try seedItems(count: count, modelContext: context) { item, index in
            if index.isMultiple(of: 3) {
                item.tags = [targetTag]
            } else if index.isMultiple(of: 5) {
                item.tags = [otherTag]
            }
        }
        try context.save()

        let options = XCTMeasureOptions()
        options.iterationCount = 3
        measure(metrics: [XCTClockMetric()], options: options) {
            do {
                _ = try repository.fetchByTag(targetTag)
            } catch {
                XCTFail("fetchByTag failed: \(error)")
            }
        }
    }

    private func benchmarkFetchStarred(count: Int) throws {
        let container = try makeContainer()
        let context = container.mainContext
        let repository = ItemRepository(modelContext: context)
        try seedItems(count: count, modelContext: context) { item, index in
            item.isStarred = index.isMultiple(of: 4)
        }

        let options = XCTMeasureOptions()
        options.iterationCount = 3
        measure(metrics: [XCTClockMetric()], options: options) {
            do {
                _ = try repository.fetchStarred()
            } catch {
                XCTFail("fetchStarred failed: \(error)")
            }
        }
    }

    private func benchmarkFetchWithFollowUp(count: Int) throws {
        let container = try makeContainer()
        let context = container.mainContext
        let repository = ItemRepository(modelContext: context)
        let followUpDate = Date(timeIntervalSince1970: 0)
        try seedItems(count: count, modelContext: context) { item, index in
            if index.isMultiple(of: 7) {
                item.followUpDate = followUpDate
            }
        }

        let options = XCTMeasureOptions()
        options.iterationCount = 3
        measure(metrics: [XCTClockMetric()], options: options) {
            do {
                _ = try repository.fetchWithFollowUp()
            } catch {
                XCTFail("fetchWithFollowUp failed: \(error)")
            }
        }
    }

    func testFetchAllPerformance100Items() throws {
        try benchmarkFetchAll(count: 100)
    }

    func testFetchAllPerformance1000Items() throws {
        try benchmarkFetchAll(count: 1000)
    }

    func testFetchAllPerformance10000Items() throws {
        try benchmarkFetchAll(count: 10000)
    }

    func testFetchCaptureItemsPerformance100Items() throws {
        try benchmarkFetchCaptureItems(count: 100)
    }

    func testFetchCaptureItemsPerformance1000Items() throws {
        try benchmarkFetchCaptureItems(count: 1000)
    }

    func testFetchCaptureItemsPerformance10000Items() throws {
        try benchmarkFetchCaptureItems(count: 10000)
    }

    func testFetchByTagPerformance100Items() throws {
        try benchmarkFetchByTag(count: 100, tag: "work")
    }

    func testFetchByTagPerformance1000Items() throws {
        try benchmarkFetchByTag(count: 1000, tag: "work")
    }

    func testFetchByTagPerformance10000Items() throws {
        try benchmarkFetchByTag(count: 10000, tag: "work")
    }

    func testFetchStarredPerformance100Items() throws {
        try benchmarkFetchStarred(count: 100)
    }

    func testFetchStarredPerformance1000Items() throws {
        try benchmarkFetchStarred(count: 1000)
    }

    func testFetchStarredPerformance10000Items() throws {
        try benchmarkFetchStarred(count: 10000)
    }

    func testFetchWithFollowUpPerformance100Items() throws {
        try benchmarkFetchWithFollowUp(count: 100)
    }

    func testFetchWithFollowUpPerformance1000Items() throws {
        try benchmarkFetchWithFollowUp(count: 1000)
    }

    func testFetchWithFollowUpPerformance10000Items() throws {
        try benchmarkFetchWithFollowUp(count: 10000)
    }
}
