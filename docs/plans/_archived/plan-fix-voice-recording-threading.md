---
id: plan-fix-voice-recording-threading
type: plan
status: uat
owners:
  - Will-Conklin
applies_to:
  - threading
  - voice
  - capture
  - bug-fix
last_updated: 2026-02-17
related:
  - design-voice-capture-testing-guide
  - design-voice-capture-test-results
depends_on: []
supersedes: []
accepted_by: @Will-Conklin
accepted_at: 2026-02-13
related_issues:
  - https://github.com/Will-Conklin/offload/issues/145
  - https://github.com/Will-Conklin/offload/issues/158
implementation_pr: https://github.com/Will-Conklin/offload/pull/152
structure_notes:
  - "Section order: Overview; Root Cause; Goals; Phases; Dependencies; Risks; User Verification; Progress."
  - "Implementation merged 2026-02-13; UAT pending in issue #158"
---

# Plan: Fix Voice Recording Service Off-Main-Actor Mutations

## Overview

`VoiceRecordingService` updates observable state from speech recognition and timer callbacks without explicit main-actor isolation, causing potential race conditions and UI corruption.

**Impact:**

- Threading warnings: UI state mutated from background threads
- Potential crashes: race conditions during concurrent state access
- UI instability: unpredictable view updates during transcription

**Location:** `ios/Offload/Data/Services/VoiceRecordingService.swift:12-13, 164-175, 179-181`

## Root Cause

### Issue 1: Missing @MainActor on Class

```swift
@Observable
final class VoiceRecordingService: @unchecked Sendable {
    var isRecording = false
    var transcribedText = ""
    // ... other observable properties
}
```

**Problem:**

- `@Observable` macro synthesizes property observers for UI binding
- Properties can be mutated from any thread
- `@unchecked Sendable` suppresses compiler warnings without fixing the issue
- No guarantee mutations happen on main thread

### Issue 2: Recognition Callback Mutates Off-Thread

```swift
recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
    if let result {
        transcribedText = result.bestTranscription.formattedString  // OFF-THREAD!
    }
    if let error {
        stopRecording()  // Calls method that mutates state OFF-THREAD!
    }
}
```

**Problem:**

- `SFSpeechRecognitionTask` callback runs on background queue
- Direct property mutations trigger `@Observable` updates off main thread
- Causes UI updates from background thread → undefined behavior

### Issue 3: Timer Callback Mutates State

```swift
recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
    self?.recordingDuration += 0.1  // Potentially off-thread
}
```

**Problem:**

- Timer callback runs on the thread that created the timer
- Without `@MainActor`, no guarantee timer runs on main thread
- If `startRecording()` called from background (unlikely but possible), timer runs there

## Goals

- Add `@MainActor` isolation to VoiceRecordingService class
- Wrap async callback mutations in `Task { @MainActor in ... }`
- Ensure all observable state updates happen on main thread
- Follow pattern from ToastManager.swift (lines 88-121)
- Add test coverage for thread safety

## Phases

### Phase 1: Add Main Actor Isolation

**Status:** Not Started

- [ ] **Update class declaration** (lines 12-13)
  - Change from: `@Observable final class VoiceRecordingService: @unchecked Sendable {`
  - Change to: `@Observable @MainActor final class VoiceRecordingService {`
  - Remove `@unchecked Sendable` (no longer needed)

### Phase 2: Fix Recognition Callback

**Status:** Not Started

- [ ] **Wrap callback body in Task** (lines 164-175)
  - Change from:

    ```swift
    recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
        guard let self else { return }
        if let result {
            transcribedText = result.bestTranscription.formattedString
        }
        if let error {
            AppLogger.voice.error(...)
            stopRecording()
        }
    }
    ```

  - Change to:

    ```swift
    recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
        Task { @MainActor [weak self] in
            guard let self else { return }
            if let result {
                transcribedText = result.bestTranscription.formattedString
            }
            if let error {
                AppLogger.voice.error(...)
                stopRecording()
            }
        }
    }
    ```

### Phase 3: Fix Timer Callback

**Status:** Not Started

- [ ] **Wrap timer body in Task** (lines 179-181)
  - Change from:

    ```swift
    recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
        self?.recordingDuration += 0.1
    }
    ```

  - Change to:

    ```swift
    recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.recordingDuration += 0.1
        }
    }
    ```

### Phase 4: Add Test Coverage

**Status:** Not Started

- [ ] **Create `ios/OffloadTests/VoiceRecordingServiceTests.swift`**
  - Mark test class with `@MainActor` for compilation verification
  - Add `testServiceIsMainActorIsolated()`
    - Compile-time verification that service is main actor isolated
    - Simply assert service exists
  - Add `testInitialState()`
    - Verify `isRecording == false`
    - Verify `isTranscribing == false`
    - Verify `transcribedText == ""`
    - Verify `errorMessage == nil`
    - Verify `recordingDuration == 0`
  - Add `testCancelRecording_ResetsState()`
    - Set recording state to active
    - Call `cancelRecording()`
    - Verify all state reset to initial values

### Phase 5: Manual Testing with Thread Sanitizer

**Status:** Not Started

- [ ] **Enable Thread Sanitizer**
  - Open Xcode scheme editor
  - Enable "Thread Sanitizer" diagnostic
  - Build and run app

- [ ] **Test voice recording flow**
  - Navigate to Capture view
  - Tap microphone button to start recording
  - Speak to trigger transcription updates
  - Verify no data race warnings in console
  - Stop recording
  - Verify clean shutdown with no warnings

- [ ] **Check logging output**
  - Verify `AppLogger.voice` messages appear correctly
  - Confirm no threading-related errors

### Phase 6: Documentation

**Status:** Not Started

- [ ] Update plan status to `completed`
- [ ] Add comment to GitHub issue #145 with implementation summary
- [ ] Consider adding to MEMORY.md as threading pattern reference

## Dependencies

**Pattern Reference:**

- `ios/Offload/DesignSystem/ToastView.swift:88-121` (ToastManager) shows correct `@MainActor` + `Task { @MainActor in }` pattern

**Prerequisites:**

- Swift Concurrency (already in use)
- iOS 15+ (already required)

**No blocking dependencies** — can proceed immediately.

## Risks

### Low: Performance Impact

**Risk:** Extra async hops for timer updates (every 0.1 seconds)

**Assessment:**

- Main thread updates necessary for UI-bound observable properties
- `Task { @MainActor in }` overhead is minimal (~microseconds)
- Timer updates are lightweight (simple property mutation)
- No measurable performance degradation expected

### Low: Callback Timing

**Risk:** Recognition callback might fire after `stopRecording()` called

**Assessment:**

- Already handled by `[weak self]` capture
- `guard let self` prevents use-after-deinit
- Main actor hop doesn't change cancellation behavior
- Callback will safely skip mutation if service released

### Low: Compiler Errors

**Risk:** Adding `@MainActor` might reveal other threading issues

**Mitigation:**

- Fix any new compiler errors as they appear
- Expected: None (all callers already on main thread from SwiftUI views)
- If found: Additional wrapping in `Task { @MainActor in }` may be needed

### Very Low: Timer RunLoop Requirement

**Risk:** Timer requires RunLoop, main actor provides this

**Assessment:**

- Current code assumes main thread (undocumented)
- After fix: Guaranteed to work (main actor ensures main thread)
- Improvement over current fragile assumption

## User Verification

### Functional Requirements

- [ ] Voice recording starts successfully
- [ ] Transcription updates appear in real-time
- [ ] Recording duration updates smoothly (every 0.1s)
- [ ] Stop recording completes cleanly
- [ ] Cancel recording resets state correctly
- [ ] Error messages display correctly on failures

### Threading Requirements

- [ ] No data race warnings with Thread Sanitizer enabled
- [ ] No threading-related crashes during recording
- [ ] No "Purple warnings" (UI updates from background thread) in console
- [ ] All observable state mutations happen on main thread

### Testing Requirements

- [ ] New unit tests pass (state management)
- [ ] Manual testing with Thread Sanitizer shows no warnings
- [ ] Voice recording flow works end-to-end
- [ ] `AppLogger.voice` output appears correctly

## Progress

### Completion Checklist

- [ ] Phase 1: Add Main Actor Isolation (all checkboxes)
- [ ] Phase 2: Fix Recognition Callback (all checkboxes)
- [ ] Phase 3: Fix Timer Callback (all checkboxes)
- [ ] Phase 4: Add Test Coverage (all checkboxes)
- [ ] Phase 5: Manual Testing with Thread Sanitizer (all checkboxes)
- [ ] Phase 6: Documentation (all checkboxes)
- [ ] User Verification: Functional Requirements (all checkboxes)
- [ ] User Verification: Threading Requirements (all checkboxes)
- [ ] User Verification: Testing Requirements (all checkboxes)

**Next action**: Begin Phase 1 after plan acceptance.
