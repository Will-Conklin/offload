// Purpose: Extensibility seam for deciding whether to surface a support nudge and what it says.
// Authority: Code-level
// Governed by: AGENTS.md

import Foundation

/// All contextual signals available to a nudge evaluator.
struct SupportNudgeSignals {
    let totalUncompleted: Int
    let capturedThisWeek: Int
    let completedThisWeek: Int
}

/// The message to display when a nudge is warranted.
struct SupportNudgeMessage {
    let headline: String
    let body: String
}

/// Decides whether to surface a support nudge and what it should say.
/// Conforming types can range from simple threshold checks to AI-generated copy.
protocol SupportNudgeEvaluating {
    /// Returns a message if a nudge should be shown, nil otherwise.
    /// Implementations may be async (e.g. a network call) — callers await.
    func evaluate(_ signals: SupportNudgeSignals) async -> SupportNudgeMessage?
}

/// Default implementation: pure rules-based, no network, no AI.
struct RulesBasedNudgeEvaluator: SupportNudgeEvaluating {
    /// Uncompleted item count at which a nudge becomes eligible.
    static let threshold = 15

    func evaluate(_ signals: SupportNudgeSignals) async -> SupportNudgeMessage? {
        guard signals.totalUncompleted >= Self.threshold else { return nil }
        return SupportNudgeMessage(
            headline: "Looks like you've got a lot going on",
            body: "That's completely OK. If anything feels heavy, reaching out to someone you trust can really help."
        )
    }
}
