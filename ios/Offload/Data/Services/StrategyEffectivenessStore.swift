// Purpose: Local persistence for executive function strategy effectiveness tracking.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: All data stays local. No cloud sync.

import Foundation

/// Tracks strategy feedback and completion-based effectiveness per challenge type.
@MainActor
final class StrategyEffectivenessStore {
    private enum Keys {
        static let feedbackRecords = "offload.exec_function.feedback_records"
        static let pendingCompletionChecks = "offload.exec_function.pending_completion_checks"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Feedback Recording

    /// Records thumbs up/down feedback for a strategy.
    func recordFeedback(strategyId: String, challengeType: String, thumbsUp: Bool) {
        var records = loadFeedbackRecords()
        let key = feedbackKey(strategyId: strategyId, challengeType: challengeType)

        var record = records[key] ?? StrategyFeedbackRecord(
            strategyId: strategyId,
            challengeType: challengeType,
            thumbsUpCount: 0,
            thumbsDownCount: 0,
            completionCount: 0,
            usageCount: 0
        )

        if thumbsUp {
            record.thumbsUpCount += 1
        } else {
            record.thumbsDownCount += 1
        }
        record.usageCount += 1

        records[key] = record
        saveFeedbackRecords(records)
    }

    /// Registers that a strategy was used on an item, to check completion within 24h.
    func registerPendingCompletionCheck(strategyId: String, challengeType: String, itemId: String) {
        var pending = loadPendingChecks()
        pending.append(PendingCompletionCheck(
            strategyId: strategyId,
            challengeType: challengeType,
            itemId: itemId,
            usedAt: Date()
        ))
        savePendingChecks(pending)
    }

    /// Marks an item as completed, crediting any strategies used within the last 24h.
    func markItemCompleted(itemId: String) {
        var pending = loadPendingChecks()
        let cutoff = Date().addingTimeInterval(-24 * 60 * 60)
        var records = loadFeedbackRecords()

        let matching = pending.filter { $0.itemId == itemId && $0.usedAt > cutoff }
        for check in matching {
            let key = feedbackKey(strategyId: check.strategyId, challengeType: check.challengeType)
            if var record = records[key] {
                record.completionCount += 1
                records[key] = record
            }
        }

        pending.removeAll { $0.itemId == itemId }
        // Also remove stale entries older than 24h
        pending.removeAll { $0.usedAt <= cutoff }

        saveFeedbackRecords(records)
        savePendingChecks(pending)
    }

    // MARK: - Strategy History for Cloud Requests

    /// Returns strategy feedback formatted for the backend request.
    func strategyHistory() -> [ExecFunctionStrategyFeedback] {
        let records = loadFeedbackRecords()
        return records.values.map { record in
            let totalFeedback = record.thumbsUpCount + record.thumbsDownCount
            let thumbsUp = totalFeedback == 0 || record.thumbsUpCount >= record.thumbsDownCount
            let ledToCompletion = record.usageCount > 0
                && Double(record.completionCount) / Double(record.usageCount) > 0.3
            return ExecFunctionStrategyFeedback(
                challengeType: record.challengeType,
                strategyId: record.strategyId,
                thumbsUp: thumbsUp,
                ledToCompletion: ledToCompletion
            )
        }
    }

    // MARK: - Private

    private func feedbackKey(strategyId: String, challengeType: String) -> String {
        "\(challengeType):\(strategyId)"
    }

    private func loadFeedbackRecords() -> [String: StrategyFeedbackRecord] {
        guard let data = defaults.data(forKey: Keys.feedbackRecords),
              let records = try? JSONDecoder().decode([String: StrategyFeedbackRecord].self, from: data) else {
            return [:]
        }
        return records
    }

    private func saveFeedbackRecords(_ records: [String: StrategyFeedbackRecord]) {
        if let data = try? JSONEncoder().encode(records) {
            defaults.set(data, forKey: Keys.feedbackRecords)
        }
    }

    private func loadPendingChecks() -> [PendingCompletionCheck] {
        guard let data = defaults.data(forKey: Keys.pendingCompletionChecks),
              let checks = try? JSONDecoder().decode([PendingCompletionCheck].self, from: data) else {
            return []
        }
        return checks
    }

    private func savePendingChecks(_ checks: [PendingCompletionCheck]) {
        if let data = try? JSONEncoder().encode(checks) {
            defaults.set(data, forKey: Keys.pendingCompletionChecks)
        }
    }
}

private struct StrategyFeedbackRecord: Codable {
    let strategyId: String
    let challengeType: String
    var thumbsUpCount: Int
    var thumbsDownCount: Int
    var completionCount: Int
    var usageCount: Int
}

private struct PendingCompletionCheck: Codable {
    let strategyId: String
    let challengeType: String
    let itemId: String
    let usedAt: Date
}
