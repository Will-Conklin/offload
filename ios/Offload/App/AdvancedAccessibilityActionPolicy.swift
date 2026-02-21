// Purpose: Shared accessibility action labels for advanced card and row interactions.
// Authority: Code-level
// Governed by: AGENTS.md

import SwiftUI

enum AdvancedAccessibilityActionPolicy {
    /// Returns the accessible action name for toggling starred state.
    static func starToggleActionName(isStarred: Bool) -> String {
        isStarred ? "Unstar" : "Star"
    }

    /// Returns the primary action name for an item card or row.
    static func primaryItemActionName(isLink: Bool) -> String {
        isLink ? "Open linked collection" : "Edit item"
    }

    /// Returns the action label used for moving a capture item into a destination.
    static func moveDestinationActionName(_ destination: MoveDestination) -> String {
        switch destination {
        case .plan:
            "Move to Plan"
        case .list:
            "Move to List"
        }
    }
}

enum AdvancedAccessibilityLayoutPolicy {
    /// Returns a minimum interactive control size for the current Dynamic Type category.
    static func controlSize(for dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 52 : Theme.HitTarget.minimum.width
    }

    /// Returns the collapsed drop-zone height for drag targets.
    static func dropZoneBaseHeight(for dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 52 : 44
    }

    /// Returns the expanded drop-zone height while a drop target is active.
    static func dropZoneTargetHeight(for dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        dynamicTypeSize.isAccessibilitySize ? 68 : 60
    }
}

extension View {
    /// Applies an accessibility action only when a matching capability exists.
    @ViewBuilder
    func accessibilityActionIf(
        _ isEnabled: Bool,
        named name: String,
        action: @escaping () -> Void
    ) -> some View {
        if isEnabled {
            self.accessibilityAction(named: name, action)
        } else {
            self
        }
    }
}
