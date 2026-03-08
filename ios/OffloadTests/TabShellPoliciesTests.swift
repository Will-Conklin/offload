// Purpose: Unit tests for tab shell accessibility and layout policies.
// Authority: Code-level
// Governed by: CLAUDE.md
// Additional instructions: Keep tests deterministic and avoid relying on network or time.

@testable import Offload
import SwiftUI
import XCTest

final class TabShellPoliciesTests: XCTestCase {
    func testTabShellTapTargetsMeetMinimumSize() {
        XCTAssertGreaterThanOrEqual(Theme.TabShell.tabButtonControlSize, Theme.HitTarget.minimum.width)
        XCTAssertGreaterThanOrEqual(Theme.TabShell.quickActionButtonSize, Theme.HitTarget.minimum.width)
        XCTAssertGreaterThanOrEqual(Theme.TabShell.mainButtonSize, Theme.HitTarget.minimum.width)
    }

    func testLayoutPolicyExpandsForAccessibilityDynamicType() {
        XCTAssertGreaterThan(
            TabShellLayoutPolicy.barHeight(for: .accessibility3),
            TabShellLayoutPolicy.barHeight(for: .large)
        )
        XCTAssertGreaterThan(
            TabShellLayoutPolicy.quickActionTraySpacing(for: .accessibility3),
            TabShellLayoutPolicy.quickActionTraySpacing(for: .large)
        )
        XCTAssertEqual(TabShellLayoutPolicy.tabLabelLineLimit(for: .large), 1)
        XCTAssertEqual(TabShellLayoutPolicy.tabLabelLineLimit(for: .accessibility3), 2)
    }

    func testMotionPolicyDisablesBounceWhenReduceMotionEnabled() {
        XCTAssertEqual(TabShellMotionPolicy.initialQuickActionBounce(reduceMotion: true), 0)
        XCTAssertEqual(TabShellMotionPolicy.overshootQuickActionBounce(reduceMotion: true), 0)
        XCTAssertEqual(TabShellMotionPolicy.initialQuickActionBounce(reduceMotion: false), Theme.TabShell.quickActionBounceInitial)
        XCTAssertEqual(TabShellMotionPolicy.overshootQuickActionBounce(reduceMotion: false), Theme.TabShell.quickActionBounceOvershoot)
    }

    func testAccessibilityMetadataUsesPredictableIdentifiersAndOrder() {
        XCTAssertEqual(TabShellAccessibility.mainButtonIdentifier, "tab-shell-offload-main")
        XCTAssertEqual(TabShellAccessibility.quickWriteIdentifier, "tab-shell-offload-write")
        XCTAssertEqual(TabShellAccessibility.quickVoiceIdentifier, "tab-shell-offload-voice")
        XCTAssertGreaterThan(
            TabShellAccessibility.quickWriteSortPriority,
            TabShellAccessibility.quickVoiceSortPriority
        )
        XCTAssertGreaterThan(
            TabShellAccessibility.quickVoiceSortPriority,
            TabShellAccessibility.mainButtonSortPriority
        )
    }
}
