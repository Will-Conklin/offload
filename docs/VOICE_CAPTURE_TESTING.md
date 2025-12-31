# Voice Capture Testing Guide

## Overview

Voice capture has been implemented for Offload (Week 1 of implementation plan). This guide walks you through testing the feature.

## What Was Implemented

### 1. VoiceRecordingService
**Location**: `ios/Offload/Data/Services/VoiceRecordingService.swift`

**Features**:
- Real-time voice recording using AVAudioEngine
- On-device speech recognition (offline-first via Speech framework)
- Live transcription updates as you speak
- Permission handling for microphone and speech recognition
- Recording duration timer
- Error handling with user-friendly messages

**Key Properties**:
- `isRecording`: Boolean indicating recording state
- `isTranscribing`: Boolean indicating transcription in progress
- `transcribedText`: String containing live transcription results
- `errorMessage`: Optional error message for display
- `recordingDuration`: TimeInterval tracking recording length

### 2. Updated CaptureSheetView
**Location**: `ios/Offload/Features/Capture/CaptureSheetView.swift`

**New UI Elements**:
- Microphone button (blue when idle, red when recording)
- Recording duration timer (MM:SS format)
- "Transcribing..." indicator
- Error message display
- Permission alert with Settings link

**Behavior**:
- Tap microphone to start recording
- Transcription appears in real-time in the text field
- Tap stop button to end recording
- Users can edit transcribed text before saving
- Canceling while recording properly cleans up
- Thought saved with `source: .voice` when transcription used

### 3. Privacy Permissions
**Location**: `ios/Offload.xcodeproj/project.pbxproj`

**Added Privacy Keys**:
- `NSMicrophoneUsageDescription`: "Offload uses the microphone to capture your thoughts via voice recording."
- `NSSpeechRecognitionUsageDescription`: "Offload uses speech recognition to transcribe your voice recordings into text."

These will trigger permission dialogs on first use.

## Testing Checklist

### Basic Functionality (10 Test Cases)

1. **First Launch - Permission Flow**
   - [ ] Open app and tap capture button
   - [ ] Tap microphone icon
   - [ ] Verify microphone permission prompt appears
   - [ ] Verify speech recognition permission prompt appears
   - [ ] Grant both permissions

2. **Simple Voice Capture**
   - [ ] Tap microphone button
   - [ ] Speak: "Buy milk and eggs"
   - [ ] Verify button turns red
   - [ ] Verify timer starts (0:00, 0:01, etc.)
   - [ ] Verify text appears in text field as you speak
   - [ ] Tap stop button
   - [ ] Verify text is editable
   - [ ] Tap Save
   - [ ] Verify thought appears in Inbox with voice icon

3. **Long Voice Note**
   - [ ] Tap microphone button
   - [ ] Speak for 30+ seconds (describe your day, list multiple tasks)
   - [ ] Verify transcription keeps up
   - [ ] Verify timer shows correct duration
   - [ ] Stop and save
   - [ ] Verify full text captured

4. **Fast Speech (ADHD Pattern Test)**
   - [ ] Tap microphone button
   - [ ] Speak rapidly: "Call dentist email boss buy groceries walk dog schedule meeting"
   - [ ] Verify transcription captures all words
   - [ ] Note: May have lower accuracy - this is expected

5. **Punctuation and Commands**
   - [ ] Tap microphone button
   - [ ] Speak: "Important: call mom. Question mark. New paragraph."
   - [ ] Verify punctuation appears correctly
   - [ ] Note: Speech framework auto-punctuates, may not be perfect

6. **Cancel While Recording**
   - [ ] Tap microphone button
   - [ ] Speak for 5 seconds
   - [ ] Tap Cancel button (not stop, but the toolbar Cancel)
   - [ ] Verify recording stops
   - [ ] Verify no thought is saved
   - [ ] Verify no audio artifacts remain

7. **Edit After Transcription**
   - [ ] Tap microphone button
   - [ ] Speak: "Buy milk and bread"
   - [ ] Stop recording
   - [ ] Edit text to add: "and eggs"
   - [ ] Save
   - [ ] Verify edited text is saved, not original

8. **Manual Text + Voice**
   - [ ] Tap capture button
   - [ ] Type: "Remember to"
   - [ ] Tap microphone button
   - [ ] Speak: "call dentist tomorrow"
   - [ ] Stop recording
   - [ ] Verify combined text: "Remember to call dentist tomorrow"
   - [ ] Save

9. **Permission Denied Flow**
   - [ ] Go to iOS Settings → Privacy → Microphone
   - [ ] Disable permission for Offload
   - [ ] Return to app
   - [ ] Tap microphone button
   - [ ] Verify alert appears
   - [ ] Tap "Open Settings"
   - [ ] Verify Settings app opens to correct screen

10. **Offline Mode**
    - [ ] Enable Airplane Mode
    - [ ] Tap microphone button
    - [ ] Speak: "Test offline transcription"
    - [ ] Verify transcription works (Speech framework is on-device)
    - [ ] Save thought
    - [ ] Disable Airplane Mode

### Error Scenarios

11. **Recording While Another App Uses Mic**
    - [ ] Start voice memo recording in Voice Memos app
    - [ ] Switch to Offload
    - [ ] Tap microphone button
    - [ ] Verify error message appears
    - [ ] Verify graceful handling (no crash)

12. **Empty Voice Recording**
    - [ ] Tap microphone button
    - [ ] Stay silent for 5 seconds
    - [ ] Tap stop
    - [ ] Verify Save button remains disabled if text is empty

### Performance Tests

13. **Transcription Latency**
    - [ ] Tap microphone
    - [ ] Speak one word: "Test"
    - [ ] Note: Text should appear within 1-2 seconds
    - [ ] Expected: <2 second latency

14. **Memory Usage**
    - [ ] Record 5 voice notes in a row (30 seconds each)
    - [ ] Monitor app performance
    - [ ] Verify no slowdown or stuttering

## Expected Results

### Success Criteria (from Implementation Plan)

- ✅ User can capture thoughts via voice
- ✅ Transcription appears in real-time
- ✅ Offline transcription works (iOS 17+)
- ✅ User can edit before saving
- ✅ Proper error handling for permissions
- ✅ Recording duration displayed
- ✅ Thought saved with correct source (.voice)

### Known Limitations

1. **Accuracy**: Speech framework may misinterpret:
   - Fast speech (ADHD patterns)
   - Accents
   - Technical terms
   - Background noise

   **Mitigation**: Text field is always editable post-transcription.

2. **Language**: Currently hardcoded to "en-US"
   - Future: Auto-detect user locale or add language picker

3. **No Audio Storage**: Only transcribed text is saved
   - Audio file is not persisted (design decision)
   - If needed later, can add optional audio attachment

4. **Single Recording at a Time**: Cannot capture multiple simultaneous recordings
   - Expected behavior for MVP

## Decision Checkpoint (Day 3)

**Per Implementation Plan**: "Does transcription quality meet bar? (Test with 10 voice notes)"

After completing tests 1-10 above:

- [ ] Transcription accuracy ≥80% for normal speech
- [ ] Works offline consistently
- [ ] No crashes or major bugs
- [ ] Permission flow clear and working

**Ship or Block Decision**:
- **Ship if**: All 4 criteria met
- **Block if**: Accuracy <80% → investigate Speech framework settings or consider fallback

## Day 7 Checkpoint

**Per Implementation Plan**: "Ship or block? (Block if <80% accuracy)"

- [ ] All 14 tests completed
- [ ] Accuracy validated across 10+ real voice notes
- [ ] User testing with 1-2 ADHD users (if available)
- [ ] No critical bugs

**Next Steps**:
- If shipped → Proceed to Week 2 (Model Relationships)
- If blocked → Debug transcription issues or defer voice to Phase 2

## Testing Notes

Use this section to record your findings:

---

### Test 1: First Launch
**Date**: ___________
**Result**: Pass / Fail
**Notes**:

---

### Test 2: Simple Voice Capture
**Date**: ___________
**Result**: Pass / Fail
**Transcription**: ___________
**Accuracy**: ____%
**Notes**:

---

(Continue for all tests...)

---

## Debugging Tips

### If Transcription Doesn't Appear:
1. Check Xcode console for errors
2. Verify both permissions granted in Settings
3. Ensure iOS 17+ (Speech framework offline requires iOS 17)
4. Try restarting app
5. Check `requiresOnDeviceRecognition = true` (should be set)

### If Recording Doesn't Start:
1. Check microphone permissions
2. Verify no other app using microphone
3. Check Xcode console for AVAudioSession errors
4. Try restarting device

### If App Crashes:
1. Check Xcode crash logs
2. Verify proper cleanup in `stopRecording()`
3. Check for retain cycles in VoiceRecordingService
4. Ensure audio engine is properly released

## Files to Review for Testing

1. [VoiceRecordingService.swift](../ios/Offload/Data/Services/VoiceRecordingService.swift)
2. [CaptureSheetView.swift](../ios/Offload/Features/Capture/CaptureSheetView.swift)
3. [Thought.swift](../ios/Offload/Domain/Models/Thought.swift) (verify `.voice` source)
4. [project.pbxproj](../ios/Offload.xcodeproj/project.pbxproj) (privacy keys)

## Next Week Preview

**Week 2 Focus**: Model Relationships & Queries
- Implement Task ↔ Project relationships
- Implement Task ↔ Tags relationships
- Build repository query methods
- Write unit tests

This will enable organizing voice-captured thoughts into tasks and projects.
