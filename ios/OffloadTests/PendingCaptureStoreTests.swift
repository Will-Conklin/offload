// Purpose: Unit tests for PendingCaptureStore shared capture queue.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Keep tests deterministic and avoid relying on network or time.

@testable import Offload
import XCTest

final class PendingCaptureStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        PendingCaptureStore.clear()
    }

    override func tearDown() {
        PendingCaptureStore.clear()
        super.tearDown()
    }

    // MARK: - enqueue truncation

    func testEnqueueTruncatesContentAtMaxLength() {
        let overLength = String(repeating: "a", count: PendingCaptureStore.maxContentLength + 100)
        let capture = PendingCapture(content: overLength)
        PendingCaptureStore.enqueue(capture)

        let loaded = PendingCaptureStore.load()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].content.count, PendingCaptureStore.maxContentLength)
    }

    func testEnqueueDoesNotTruncateContentAtMaxLength() {
        let exactLength = String(repeating: "b", count: PendingCaptureStore.maxContentLength)
        let capture = PendingCapture(content: exactLength)
        PendingCaptureStore.enqueue(capture)

        let loaded = PendingCaptureStore.load()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].content.count, PendingCaptureStore.maxContentLength)
    }

    func testEnqueueDoesNotTruncateBelowMaxLength() {
        let content = "short content"
        let capture = PendingCapture(content: content)
        PendingCaptureStore.enqueue(capture)

        let loaded = PendingCaptureStore.load()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded[0].content, content)
    }

    // MARK: - loadAndClear atomicity

    func testLoadAndClearReturnsEnqueuedItems() {
        PendingCaptureStore.enqueue(PendingCapture(content: "item 1"))
        PendingCaptureStore.enqueue(PendingCapture(content: "item 2"))

        let result = PendingCaptureStore.loadAndClear()
        XCTAssertEqual(result.count, 2)
    }

    func testLoadAndClearEmptiesTheQueue() {
        PendingCaptureStore.enqueue(PendingCapture(content: "item 1"))
        _ = PendingCaptureStore.loadAndClear()

        let remaining = PendingCaptureStore.load()
        XCTAssertTrue(remaining.isEmpty)
    }

    func testLoadAndClearOnEmptyQueueReturnsEmptyArray() {
        let result = PendingCaptureStore.loadAndClear()
        XCTAssertTrue(result.isEmpty)
    }

    func testLoadDoesNotClearQueue() {
        PendingCaptureStore.enqueue(PendingCapture(content: "persistent"))
        _ = PendingCaptureStore.load()
        let second = PendingCaptureStore.load()
        XCTAssertEqual(second.count, 1)
    }

    // MARK: - encoding / decoding edge cases

    func testEnqueuePreservesType() {
        let capture = PendingCapture(content: "test", type: "task")
        PendingCaptureStore.enqueue(capture)

        let loaded = PendingCaptureStore.load()
        XCTAssertEqual(loaded[0].type, "task")
    }

    func testEnqueuePreservesSourceURL() {
        let capture = PendingCapture(content: "test", sourceURL: "https://example.com")
        PendingCaptureStore.enqueue(capture)

        let loaded = PendingCaptureStore.load()
        XCTAssertEqual(loaded[0].sourceURL, "https://example.com")
    }

    func testEnqueuePreservesNilFields() {
        let capture = PendingCapture(content: "bare capture")
        PendingCaptureStore.enqueue(capture)

        let loaded = PendingCaptureStore.load()
        XCTAssertNil(loaded[0].type)
        XCTAssertNil(loaded[0].sourceURL)
    }

    func testEnqueuePreservesMultipleItemsInOrder() {
        let contents = ["first", "second", "third"]
        for content in contents {
            PendingCaptureStore.enqueue(PendingCapture(content: content))
        }

        let loaded = PendingCaptureStore.load()
        XCTAssertEqual(loaded.count, 3)
        XCTAssertEqual(loaded.map(\.content), contents)
    }

    func testEnqueueHandlesUnicodeContent() {
        let unicode = "🧠 Offload this: café résumé naïve"
        PendingCaptureStore.enqueue(PendingCapture(content: unicode))

        let loaded = PendingCaptureStore.load()
        XCTAssertEqual(loaded[0].content, unicode)
    }

    func testEnqueueOnEmptyQueue() {
        let result = PendingCaptureStore.load()
        XCTAssertTrue(result.isEmpty)
    }
}
