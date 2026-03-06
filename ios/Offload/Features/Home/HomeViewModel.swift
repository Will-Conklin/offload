// Purpose: Home feature view model for dashboard stats and timeline data.
// Authority: Code-level
// Governed by: AGENTS.md

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

        let allItems = try itemRepository.fetchAll()
        let totalUncompleted = allItems.filter { $0.completedAt == nil }.count

        let signals = SupportNudgeSignals(
            totalUncompleted: totalUncompleted,
            capturedThisWeek: capturedThisWeek,
            completedThisWeek: completedThisWeek
        )
        supportNudgeMessage = await nudgeEvaluator.evaluate(signals)

        let now = Date()
        let sevenDaysOut = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        timelineItems = try itemRepository.fetchItemsWithFollowUpDate(from: now, to: sevenDaysOut)
    }
}
