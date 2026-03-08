// Purpose: Shared policy values for tab shell layout, accessibility, and motion.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Keep policy values deterministic and aligned with Theme tokens.

import SwiftUI

enum TabShellLayoutPolicy {
    /// Returns the tab bar height tuned for the current Dynamic Type category.
    static func barHeight(for dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        dynamicTypeSize.isAccessibilitySize ? Theme.TabShell.barHeightAccessibility : Theme.TabShell.barHeight
    }

    /// Returns quick-action spacing adjusted to avoid crowding at large text sizes.
    static func quickActionTraySpacing(for dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        dynamicTypeSize.isAccessibilitySize
            ? Theme.TabShell.quickActionTrayAccessibilitySpacing
            : Theme.TabShell.quickActionTraySpacing
    }

    /// Returns the allowed line count for tab labels at the provided Dynamic Type size.
    static func tabLabelLineLimit(for dynamicTypeSize: DynamicTypeSize) -> Int {
        dynamicTypeSize.isAccessibilitySize ? 2 : 1
    }

    /// Returns label scaling bounds for tab text to minimize clipping at larger sizes.
    static func tabLabelMinimumScaleFactor(for dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 0.9 : 1
    }
}

enum TabShellMotionPolicy {
    /// Returns an optional animation that disables non-essential motion when Reduce Motion is enabled.
    static func animation(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        Theme.Animations.optionalMotion(animation, reduceMotion: reduceMotion)
    }

    /// Returns the initial bounce amount applied when opening the quick-action tray.
    static func initialQuickActionBounce(reduceMotion: Bool) -> CGFloat {
        reduceMotion ? 0 : Theme.TabShell.quickActionBounceInitial
    }

    /// Returns the overshoot bounce amount used for the quick-action tray spring.
    static func overshootQuickActionBounce(reduceMotion: Bool) -> CGFloat {
        reduceMotion ? 0 : Theme.TabShell.quickActionBounceOvershoot
    }

    /// Returns whether secondary bounce motion should run for the quick-action tray.
    static func shouldAnimateBounce(reduceMotion: Bool) -> Bool {
        !reduceMotion
    }
}

enum TabShellAccessibility {
    static let tabBarIdentifier = "tab-shell-root"
    static let offloadGroupIdentifier = "tab-shell-offload-group"
    static let offloadQuickTrayIdentifier = "tab-shell-offload-quick-tray"
    static let mainButtonIdentifier = "tab-shell-offload-main"
    static let quickWriteIdentifier = "tab-shell-offload-write"
    static let quickVoiceIdentifier = "tab-shell-offload-voice"

    static let offloadGroupLabel = "Offload"
    static let offloadMainCollapsedLabel = "Offload"
    static let offloadMainExpandedLabel = "Close Offload actions"
    static let offloadMainHint = "Shows quick capture actions"
    static let quickWriteLabel = "Write"
    static let quickVoiceLabel = "Voice"
    static let quickActionHintSuffix = "capture"
    static let tabSelectionSelectedValue = "Selected"
    static let tabSelectionNotSelectedValue = "Not selected"

    static let quickWriteSortPriority: Double = 3
    static let quickVoiceSortPriority: Double = 2
    static let mainButtonSortPriority: Double = 1

    /// Returns the accessibility identifier for a specific tab button.
    static func identifier(for tab: MainTabView.Tab) -> String {
        switch tab {
        case .home:
            "tab-shell-home"
        case .review:
            "tab-shell-review"
        case .organize:
            "tab-shell-organize"
        case .account:
            "tab-shell-account"
        }
    }
}
