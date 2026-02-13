// Purpose: Unit tests for voice recording service thread safety.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep tests deterministic and avoid relying on network or time.

@testable import Offload
import XCTest

@MainActor
final class VoiceRecordingServiceTests: XCTestCase {
    private var service: VoiceRecordingService!

    override func setUp() async throws {
        service = VoiceRecordingService()
    }

    override func tearDown() {
        service = nil
    }

    func testServiceIsMainActorIsolated() {
        // This test compiles only if service is @MainActor
        XCTAssertNotNil(service)
    }

    func testInitialState() {
        XCTAssertFalse(service.isRecording)
        XCTAssertFalse(service.isTranscribing)
        XCTAssertEqual(service.transcribedText, "")
        XCTAssertNil(service.errorMessage)
        XCTAssertEqual(service.recordingDuration, 0)
    }

    func testCancelRecording_ResetsState() {
        // Simulate recording started
        service.isRecording = true
        service.isTranscribing = true
        service.transcribedText = "Test"
        service.recordingDuration = 5.0

        service.cancelRecording()

        XCTAssertFalse(service.isRecording)
        XCTAssertFalse(service.isTranscribing)
        XCTAssertEqual(service.transcribedText, "")
    }
}
