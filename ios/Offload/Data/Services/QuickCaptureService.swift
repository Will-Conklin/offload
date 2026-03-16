// Purpose: Flushes extension-queued captures from App Group UserDefaults into SwiftData.
// Authority: Code-level
// Governed by: CLAUDE.md

import OSLog
import SwiftData
import SwiftUI

/// Listens for app-foreground events and materialises any captures queued by extensions into SwiftData.
@MainActor
final class QuickCaptureService {
    private let itemRepository: ItemRepository

    init(itemRepository: ItemRepository) {
        self.itemRepository = itemRepository
    }

    /// Moves all `PendingCapture` records from the App Group queue into SwiftData.
    /// Safe to call on every foreground transition — a no-op when the queue is empty.
    /// Uses `loadAndClear()` to snapshot and remove the queue atomically before processing,
    /// so a concurrent extension enqueue cannot be lost by a subsequent clear.
    func flushPending() {
        let pending = PendingCaptureStore.loadAndClear()
        guard !pending.isEmpty else { return }
        AppLogger.workflow.info("QuickCaptureService flush - count: \(pending.count, privacy: .public)")
        var flushed = 0
        for capture in pending {
            do {
                _ = try itemRepository.create(
                    type: capture.type,
                    content: capture.content,
                    attachmentData: nil,
                    tags: [],
                    isStarred: false
                )
                flushed += 1
            } catch {
                AppLogger.workflow.error(
                    "QuickCaptureService flush failed - id: \(capture.id, privacy: .public), error: \(error.localizedDescription, privacy: .public)"
                )
            }
        }
        if flushed > 0 {
            NotificationCenter.default.post(name: .captureItemsChanged, object: nil)
            AppLogger.workflow.info("QuickCaptureService flush completed - flushed: \(flushed, privacy: .public)")
        }
    }
}
