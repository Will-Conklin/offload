// Purpose: Unit tests for shared swipe gesture state transitions.
// Authority: Code-level
// Governed by: AGENTS.md

@testable import Offload
import XCTest

final class SwipeInteractionModelTests: XCTestCase {
    func testEndStateReturnsClosedForShortTrailingSwipe() {
        let model = SwipeInteractionModel.trailingDelete

        let endState = model.endState(
            startOffset: 0,
            translation: CGSize(width: -20, height: 0)
        )

        XCTAssertEqual(endState, .closed)
    }

    func testEndStateReturnsRevealedForMediumTrailingSwipe() {
        let model = SwipeInteractionModel.trailingDelete

        let endState = model.endState(
            startOffset: 0,
            translation: CGSize(width: -60, height: 0)
        )

        XCTAssertEqual(endState, .revealed)
    }

    func testEndStateReturnsTriggerTrailingActionForFullSwipe() {
        let model = SwipeInteractionModel.trailingDelete

        let endState = model.endState(
            startOffset: 0,
            translation: CGSize(width: -140, height: 0)
        )

        XCTAssertEqual(endState, .triggerTrailingAction)
    }

    func testEndStateKeepsRevealedStateForVerticalGestureWhenAlreadyRevealed() {
        let model = SwipeInteractionModel.trailingDelete

        let endState = model.endState(
            startOffset: model.revealedOffset,
            translation: CGSize(width: 5, height: 20)
        )

        XCTAssertEqual(endState, .revealed)
    }

    func testEndStateReturnsTriggerLeadingActionWhenLeadingActionEnabled() {
        let model = SwipeInteractionModel.capture

        let endState = model.endState(
            startOffset: 0,
            translation: CGSize(width: 130, height: 0)
        )

        XCTAssertEqual(endState, .triggerLeadingAction)
    }

    func testDragOffsetClampsToTrailingBound() {
        let model = SwipeInteractionModel.trailingDelete

        let dragOffset = model.dragOffset(
            startOffset: 0,
            translation: CGSize(width: -300, height: 0)
        )

        XCTAssertEqual(dragOffset, -model.maxTrailingOffset)
    }

    func testDragOffsetClampsToLeadingBoundForCaptureModel() {
        let model = SwipeInteractionModel.capture

        let dragOffset = model.dragOffset(
            startOffset: 0,
            translation: CGSize(width: 300, height: 0)
        )

        XCTAssertEqual(dragOffset, model.maxLeadingOffset)
    }
}
