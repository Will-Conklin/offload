// Purpose: Shared swipe gesture state model used across card and row views.
// Authority: Code-level
// Governed by: AGENTS.md

import CoreGraphics

enum SwipeEndState: Equatable {
    case closed
    case revealed
    case triggerLeadingAction
    case triggerTrailingAction
}

struct SwipeInteractionModel {
    let supportsLeadingAction: Bool
    let supportsTrailingReveal: Bool

    let revealOffset: CGFloat
    let revealThreshold: CGFloat
    let actionThreshold: CGFloat
    let maxTrailingOffset: CGFloat
    let maxLeadingOffset: CGFloat

    static let trailingDelete = SwipeInteractionModel(
        supportsLeadingAction: false,
        supportsTrailingReveal: true
    )

    static let capture = SwipeInteractionModel(
        supportsLeadingAction: true,
        supportsTrailingReveal: true
    )

    init(
        supportsLeadingAction: Bool,
        supportsTrailingReveal: Bool,
        revealOffset: CGFloat = 84,
        revealThreshold: CGFloat = 44,
        actionThreshold: CGFloat = 110,
        maxTrailingOffset: CGFloat = 168,
        maxLeadingOffset: CGFloat = 120
    ) {
        self.supportsLeadingAction = supportsLeadingAction
        self.supportsTrailingReveal = supportsTrailingReveal
        self.revealOffset = revealOffset
        self.revealThreshold = revealThreshold
        self.actionThreshold = actionThreshold
        self.maxTrailingOffset = maxTrailingOffset
        self.maxLeadingOffset = maxLeadingOffset
    }

    /// Calculates the card/row horizontal offset during a drag.
    /// - Parameters:
    ///   - startOffset: The offset at drag start.
    ///   - translation: The current drag translation from SwiftUI.
    /// - Returns: A clamped horizontal offset, or `nil` when gesture is not primarily horizontal.
    func dragOffset(startOffset: CGFloat, translation: CGSize) -> CGFloat? {
        guard isHorizontal(translation: translation) else {
            return nil
        }

        return clamped(startOffset + translation.width)
    }

    /// Resolves the gesture outcome once dragging ends.
    /// - Parameters:
    ///   - startOffset: The offset at drag start.
    ///   - translation: The final drag translation from SwiftUI.
    /// - Returns: The terminal swipe state used to snap, reveal, or trigger actions.
    func endState(startOffset: CGFloat, translation: CGSize) -> SwipeEndState {
        guard isHorizontal(translation: translation) else {
            return isRevealed(offset: startOffset) ? .revealed : .closed
        }

        let finalOffset = clamped(startOffset + translation.width)

        if supportsLeadingAction, finalOffset >= actionThreshold {
            return .triggerLeadingAction
        }

        if supportsTrailingReveal, finalOffset <= -actionThreshold {
            return .triggerTrailingAction
        }

        if supportsTrailingReveal, finalOffset <= -revealThreshold {
            return .revealed
        }

        return .closed
    }

    /// Returns the resting offset for the revealed trailing action state.
    var revealedOffset: CGFloat {
        supportsTrailingReveal ? -revealOffset : 0
    }

    /// Indicates whether the trailing delete affordance should be treated as revealed.
    /// - Parameter offset: Current horizontal offset.
    /// - Returns: `true` when offset has crossed reveal threshold.
    func isRevealed(offset: CGFloat) -> Bool {
        supportsTrailingReveal && offset <= -revealThreshold
    }

    /// Produces normalized delete-affordance visibility based on swipe offset.
    /// - Parameter offset: Current horizontal offset.
    /// - Returns: A value between `0` and `1`.
    func trailingProgress(offset: CGFloat) -> Double {
        guard supportsTrailingReveal else { return 0 }
        let normalized = Double((-offset) / revealOffset)
        return min(max(normalized, 0), 1)
    }

    /// Produces normalized leading-affordance visibility based on swipe offset.
    /// - Parameter offset: Current horizontal offset (positive when swiping right).
    /// - Returns: A value between `0` and `1`.
    func leadingProgress(offset: CGFloat) -> Double {
        guard supportsLeadingAction else { return 0 }
        let normalized = Double(offset / maxLeadingOffset)
        return min(max(normalized, 0), 1)
    }

    /// Returns whether the leading action threshold has been reached.
    /// - Parameter offset: Current horizontal offset.
    /// - Returns: `true` when offset has crossed the action threshold.
    func isLeadingTriggered(offset: CGFloat) -> Bool {
        supportsLeadingAction && offset >= actionThreshold
    }

    /// Returns whether the gesture translation is primarily horizontal.
    /// - Parameter translation: The current drag translation from SwiftUI.
    /// - Returns: `true` when horizontal movement exceeds vertical movement.
    func isHorizontal(translation: CGSize) -> Bool {
        abs(translation.width) > abs(translation.height)
    }

    private var minOffset: CGFloat {
        supportsTrailingReveal ? -maxTrailingOffset : 0
    }

    private var maxOffset: CGFloat {
        supportsLeadingAction ? maxLeadingOffset : 0
    }

    private func clamped(_ value: CGFloat) -> CGFloat {
        min(max(value, minOffset), maxOffset)
    }

}
