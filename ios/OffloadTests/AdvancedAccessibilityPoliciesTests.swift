// Purpose: Unit tests for advanced accessibility action label policy.
// Authority: Code-level
// Governed by: AGENTS.md

@testable import Offload
import SwiftUI
import XCTest

final class AdvancedAccessibilityPoliciesTests: XCTestCase {
    func testStarToggleActionNamesReflectCurrentState() {
        XCTAssertEqual(AdvancedAccessibilityActionPolicy.starToggleActionName(isStarred: false), "Star")
        XCTAssertEqual(AdvancedAccessibilityActionPolicy.starToggleActionName(isStarred: true), "Unstar")
    }

    func testPrimaryItemActionNameChangesForLinkedItems() {
        XCTAssertEqual(AdvancedAccessibilityActionPolicy.primaryItemActionName(isLink: false), "Edit item")
        XCTAssertEqual(AdvancedAccessibilityActionPolicy.primaryItemActionName(isLink: true), "Open linked collection")
    }

    func testMoveDestinationActionNamesAreDeterministic() {
        XCTAssertEqual(AdvancedAccessibilityActionPolicy.moveDestinationActionName(.plan), "Move to Plan")
        XCTAssertEqual(AdvancedAccessibilityActionPolicy.moveDestinationActionName(.list), "Move to List")
    }

    func testLayoutPolicyControlSizeScalesForAccessibilityDynamicType() {
        XCTAssertEqual(
            AdvancedAccessibilityLayoutPolicy.controlSize(for: .large),
            Theme.HitTarget.minimum.width
        )
        XCTAssertGreaterThan(
            AdvancedAccessibilityLayoutPolicy.controlSize(for: .accessibility3),
            AdvancedAccessibilityLayoutPolicy.controlSize(for: .large)
        )
    }

    func testLayoutPolicyDropZoneHeightsScaleForAccessibilityDynamicType() {
        XCTAssertEqual(AdvancedAccessibilityLayoutPolicy.dropZoneBaseHeight(for: .large), 44)
        XCTAssertEqual(AdvancedAccessibilityLayoutPolicy.dropZoneTargetHeight(for: .large), 60)
        XCTAssertEqual(AdvancedAccessibilityLayoutPolicy.dropZoneBaseHeight(for: .accessibility3), 52)
        XCTAssertEqual(AdvancedAccessibilityLayoutPolicy.dropZoneTargetHeight(for: .accessibility3), 68)
    }
}
