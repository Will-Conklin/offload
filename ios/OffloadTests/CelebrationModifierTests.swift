// Purpose: Tests for celebration animation types and configuration.
// Authority: Code-level
// Governed by: CLAUDE.md

@testable import Offload
import XCTest

final class CelebrationModifierTests: XCTestCase {
    // MARK: - CelebrationStyle Properties

    func testItemCompletedHapticIsLight() {
        XCTAssertEqual(CelebrationStyle.itemCompleted.hapticStyle, .light)
    }

    func testFirstCaptureHapticIsMedium() {
        XCTAssertEqual(CelebrationStyle.firstCapture.hapticStyle, .medium)
    }

    func testCollectionCompletedHapticIsMedium() {
        XCTAssertEqual(CelebrationStyle.collectionCompleted.hapticStyle, .medium)
    }

    func testItemCompletedHasNoParticles() {
        XCTAssertFalse(CelebrationStyle.itemCompleted.showsParticles)
    }

    func testFirstCaptureHasParticles() {
        XCTAssertTrue(CelebrationStyle.firstCapture.showsParticles)
    }

    func testCollectionCompletedHasParticles() {
        XCTAssertTrue(CelebrationStyle.collectionCompleted.showsParticles)
    }

    func testParticleCountRange() {
        let style = CelebrationStyle.firstCapture
        XCTAssertGreaterThanOrEqual(style.particleCount, 5)
        XCTAssertLessThanOrEqual(style.particleCount, 8)
    }

    func testItemCompletedScaleFactor() {
        XCTAssertEqual(CelebrationStyle.itemCompleted.scalePeak, 1.15, accuracy: 0.01)
    }

    func testFirstCaptureScaleFactor() {
        XCTAssertEqual(CelebrationStyle.firstCapture.scalePeak, 1.15, accuracy: 0.01)
    }

    func testCollectionCompletedScaleFactor() {
        XCTAssertEqual(CelebrationStyle.collectionCompleted.scalePeak, 1.0, accuracy: 0.01)
    }

    // MARK: - Duration

    func testItemCompletedDuration() {
        XCTAssertEqual(CelebrationStyle.itemCompleted.duration, 0.4, accuracy: 0.01)
    }

    func testFirstCaptureDuration() {
        XCTAssertEqual(CelebrationStyle.firstCapture.duration, 1.5, accuracy: 0.01)
    }

    func testCollectionCompletedDuration() {
        XCTAssertEqual(CelebrationStyle.collectionCompleted.duration, 2.0, accuracy: 0.01)
    }

    // MARK: - Collection Completion Detection

    func testAllItemsCompleteDetection() {
        let completedDates: [Date?] = [Date(), Date(), Date()]
        let allComplete = completedDates.allSatisfy { $0 != nil }
        XCTAssertTrue(allComplete)
    }

    func testNotAllItemsCompleteDetection() {
        let completedDates: [Date?] = [Date(), nil, Date()]
        let allComplete = completedDates.allSatisfy { $0 != nil }
        XCTAssertFalse(allComplete)
    }

    func testEmptyCollectionIsNotComplete() {
        let completedDates: [Date?] = []
        let allComplete = !completedDates.isEmpty && completedDates.allSatisfy { $0 != nil }
        XCTAssertFalse(allComplete)
    }
}
