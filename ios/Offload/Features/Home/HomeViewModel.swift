// Purpose: Home feature view model for dashboard stats and timeline data.
// Authority: Code-level
// Governed by: CLAUDE.md

import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
    private(set) var capturedThisWeek: Int = 0
    private(set) var completedThisWeek: Int = 0
    private(set) var activeCollectionCount: Int = 0
    private(set) var supportNudgeMessage: SupportNudgeMessage?
    private(set) var timelineItems: [Item] = []
    private(set) var isLoading = false

    private let nudgeEvaluator: any SupportNudgeEvaluating

    /// - Parameter nudgeEvaluator: Strategy for deciding whether to show a support nudge and what copy to use.
    ///   Defaults to `RulesBasedNudgeEvaluator`. Swap in an AI-backed evaluator without changing callers.
    init(nudgeEvaluator: any SupportNudgeEvaluating = RulesBasedNudgeEvaluator()) {
        self.nudgeEvaluator = nudgeEvaluator
    }

    /// Loads dashboard stats and timeline items.
    /// - Parameters:
    ///   - itemRepository: Repository used to fetch item data.
    ///   - collectionRepository: Repository used to fetch collection data.
    func loadStats(
        using itemRepository: ItemRepository,
        collectionRepository: CollectionRepository
    ) async throws {
        isLoading = true
        defer { isLoading = false }

        capturedThisWeek = try itemRepository.fetchCapturedThisWeek().count
        completedThisWeek = try itemRepository.fetchCompletedThisWeek().count
        activeCollectionCount = try collectionRepository.fetchActiveCollections().count

        let totalUncompleted = try itemRepository.fetchIncomplete().count

        let signals = SupportNudgeSignals(
            totalUncompleted: totalUncompleted,
            capturedThisWeek: capturedThisWeek,
            completedThisWeek: completedThisWeek
        )
        // Capture evaluator explicitly before the task group to avoid accessing
        // @MainActor-isolated state from within a concurrent Sendable closure.
        let evaluator = nudgeEvaluator
        // Guard against a slow or hung evaluator (e.g. network-backed); fall back to nil on timeout.
        supportNudgeMessage = await withTaskGroup(of: SupportNudgeMessage?.self) { group in
            group.addTask { await evaluator.evaluate(signals) }
            group.addTask {
                try? await Task.sleep(for: .seconds(3))
                return nil
            }
            let result = await group.next()
            group.cancelAll()
            return result ?? nil
        }

        timelineItems = try Self.upcomingItems(from: itemRepository)
    }

    /// Refreshes only the timeline items — lighter than a full `loadStats` reload.
    func reloadTimeline(using itemRepository: ItemRepository) throws {
        timelineItems = try Self.upcomingItems(from: itemRepository)
    }

    private static func upcomingItems(from itemRepository: ItemRepository) throws -> [Item] {
        let now = Date()
        let sevenDaysOut = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        return try itemRepository.fetchItemsWithFollowUpDate(from: now, to: sevenDaysOut)
    }
}
