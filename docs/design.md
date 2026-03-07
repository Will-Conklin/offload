# Offload — Design

## Navigation Shell

Five-tab bottom bar with a centered Offload CTA. See `architecture.md` for tab definitions.

**Tab bar behavior:**

- Stays anchored and visible across all `NavigationStack` pushes
- Offload CTA (center button) protrudes above the bar border and expands to reveal labeled Write and Voice quick actions
- Write and Voice actions open `CaptureComposeView` as a sheet
- Account tab lands on `AccountView`; Settings is one tap from there
- Tab selection states use `Theme` selection highlight rules

**Testing:**

- Verify tab bar stays visible across `NavigationStack` pushes
- Tap CTA actions → confirm `CaptureComposeView` appears with correct mode
- Confirm Account tab opens `AccountView` and Settings is accessible
- Validate safe-area padding on small devices and with Dynamic Type

---

## Collection Management

### Plan ↔ List Conversion

Entry point: long-press a collection card in `OrganizeView` → context menu → Convert.

**Plan → List:** Show `confirmationDialog` describing hierarchy loss. On confirm: clear all `parentId` values, persist depth-first traversal order to `position`.

**List → Plan:** Set `isStructured = true`, assign positions based on current list order. No hierarchy introduced.

After conversion: collection stays in place, items preserved, views refresh via repository notifications.

**Testing:**

- Convert a plan with nested items to a list → verify hierarchy flattened
- Convert a list to a plan → verify item ordering preserved
- Confirm warning shows only for plan → list conversion
- Ensure no orphaned items or broken CollectionItem links

### Drag & Drop Ordering

Implemented in `CollectionDetailView` using SwiftUI drag-and-drop APIs.

**List reorder:** Drag item to new position → repository updates `CollectionItem.position` for all affected rows.

**Plan nesting:** Drag item onto another item → sets `parentId` + adjusts sibling positions. Show indentation preview while dragging. Insertion indicator between rows.

Collapse/expand state is session-only (not persisted).

**Testing:**

- Reorder items in a list → verify persistence after relaunch
- Drag plan item onto another → confirm it becomes a child
- Collapse parent → ensure child visibility toggles (session-only)
- Convert plan to list → verify hierarchy flattened but ordering deterministic

---

## Search & Tags

Search icon in Capture and Organize toolbars reveals a floating search bar.

**Text search:** Queries `Item.content` via SwiftData predicate, results update as user types.

**Tag filter:** Matching tags from results appear as selectable chips below the search bar. Selecting a chip sets `selectedTagId` and scopes results to that tag. Tag matches use `Item.tags` relationship only.

**Clearing:** Clears both `searchText` and `selectedTagId`, restores full list.

UI: Search bar anchors below top-right icon, spans ~2/3 view width. Non-blocking — quick to dismiss.

**Testing:**

- Search by text → results update as user types
- Select tag chip → results scoped to that tag
- Clear search → full list returns
- Validate placement across device sizes and with Dynamic Type

---

## Voice Capture

**Implementation:** `VoiceRecordingService` (AVAudioEngine + Apple Speech framework). On-device, offline, iOS 17+.

**Key behavior:**

- One-tap record/stop
- Live transcription appears in text field as user speaks
- Recording duration timer (MM:SS)
- User can edit transcribed text before saving
- Cancel while recording: stops recording, nothing saved
- Capture saved with `source: .voice` when transcription used
- Language hardcoded to `en-US` (locale detection is future work)
- Audio file not persisted — transcription only

**Permissions required:**

- `NSMicrophoneUsageDescription` — triggers on first use
- `NSSpeechRecognitionUsageDescription` — triggers on first use

**Known limitations:**

- Lower accuracy with fast speech, accents, background noise
- Single recording at a time (expected)
- Text field is always editable post-transcription as mitigation

### Voice Capture Testing Checklist

Run on a physical device (not simulator).

**Basic functionality:**

- [ ] First launch: microphone + speech recognition permissions appear and can be granted
- [ ] Simple voice capture: button turns red, timer starts, text appears in real-time, tap stop, text editable, save → item appears with voice indicator
- [ ] Long voice note (30+ seconds): transcription keeps up, full text captured
- [ ] Fast speech: all words transcribed (some degradation expected)
- [ ] Cancel while recording: recording stops, no item saved, no audio artifacts
- [ ] Edit after transcription: edited text saved, not original
- [ ] Manual text + voice combined: text concatenates correctly
- [ ] Offline (Airplane Mode): transcription works (on-device Speech framework)

**Error scenarios:**

- [ ] Permission denied: alert appears with "Open Settings" link, Settings app opens to correct screen
- [ ] Another app using mic: error message appears, graceful handling (no crash)
- [ ] Empty recording (silence): Save button remains disabled

**Performance:**

- [ ] Transcription latency: text appears within 1–2 seconds of speaking
- [ ] Memory: 5 consecutive 30-second recordings, no slowdown or stuttering

**Success criteria:**

- Transcription accuracy ≥80% for normal speech
- Works offline consistently
- No crashes
- Permission flow clear

**Debugging tips:**

- No transcription: check both permissions granted; verify iOS 17+; check `requiresOnDeviceRecognition = true`
- Recording won't start: check mic permissions; check no other app using mic; check AVAudioSession errors in console
- Crash: check `stopRecording()` cleanup; check for retain cycles in `VoiceRecordingService`

---

## Manual Testing Checklist

Run on at least one iPhone and one iPad. Use a physical device for voice capture.

**Preconditions:** Fresh install or cleared local data. Local-only mode (no backend required).

### Capture (Text)

- [ ] Create a text capture from the main entry point
- [ ] Confirm it appears in the capture list immediately
- [ ] Edit the capture content and verify the update persists
- [ ] Delete a capture and confirm undo restores it

### Capture (Attachments)

- [ ] Add a photo attachment to a capture and verify it renders
- [ ] Remove the attachment and confirm the capture remains intact

### Tags, Star, Follow-Up

- [ ] Add a tag, then remove it, and confirm the list updates
- [ ] Star and unstar a capture
- [ ] Set and clear a follow-up date

### Organize (Plans and Lists)

- [ ] Create a plan (structured collection)
- [ ] Create a list (unstructured collection)
- [ ] Move a capture into a plan and verify it appears in order
- [ ] Move a capture into a list and verify it appears
- [ ] Reorder items within a plan and confirm order persists after relaunch
- [ ] Mark a plan item complete and confirm it moves to completed state

### Voice Capture Testing

- [ ] Run through the Voice Capture Testing Checklist above

### Settings

- [ ] Open Settings and verify all sections render
- [ ] Open each external link and confirm it resolves

### Persistence

- [ ] Force quit and relaunch; verify recent changes persist
- [ ] Background the app and return; verify UI state is consistent

### Accessibility (Baseline)

- [ ] Enable Dynamic Type (Large/Extra Large) and verify layout stability
- [ ] Enable Reduce Motion and verify animations are minimized
- [ ] Enable VoiceOver and confirm core controls have labels

---

## Advanced Accessibility Testing Checklist

Run after any accessibility-related code changes. Requires a physical device.

**Preconditions:**

- Build containing `AdvancedAccessibilityActionPolicy`, `AdvancedAccessibilityLayoutPolicy`, `accessibilityActionIf()` extension
- At least: one capture item, one list collection, one plan collection, one linked item in a collection
- Enable and test: VoiceOver, Switch Control, Dynamic Type (standard and accessibility sizes), Reduce Motion (ON and OFF)

**Device matrix:**

| Device | OS | Build | Tester | Date | Result |
| --- | --- | --- | --- | --- | --- |
| iPhone | iOS | Debug/TestFlight | TBD | YYYY-MM-DD | Pass/Fail |
| iPad | iPadOS | Debug/TestFlight | TBD | YYYY-MM-DD | Pass/Fail |

### VoiceOver and Switch Control Action Parity

- [ ] Capture card exposes actions: Complete, Delete, Star/Unstar, Move to Plan, Move to List
- [ ] Capture card Star action toggles correctly; label updates between "Star" and "Unstar"
- [ ] Collection detail row exposes actions: Delete, Edit item/Open linked collection, Star/Unstar
- [ ] Linked collection row action says "Open linked collection" and navigates to linked destination
- [ ] Non-linked row action says "Edit item" and opens edit flow
- [ ] Organize collection card exposes Delete and Star/Unstar actions
- [ ] Convert action appears only for cards where conversion is available
- [ ] Move up/down actions appear only where corresponding handlers exist (no inert/no-op actions)

### Dynamic Type and Interaction Sizing

- [ ] At default Dynamic Type, controls remain at baseline sizing and do not clip content
- [ ] At accessibility Dynamic Type sizes, chevron/action controls visibly increase touch size
- [ ] At accessibility Dynamic Type sizes, drop zone idle/target heights increase and remain visually aligned
- [ ] Drag and drop remains functional at accessibility Dynamic Type sizes
- [ ] Swipe and tap gesture targets remain usable at accessibility Dynamic Type sizes

### Reduce Motion and Interaction Integrity

- [ ] With Reduce Motion ON, action behaviors remain functional and predictable
- [ ] With Reduce Motion OFF, animation behavior is smooth with no jitter
- [ ] No accessibility action becomes unavailable due to motion setting changes

**Exit criteria:**

- All items pass on at least one iPhone and one iPad
- Any failures have linked follow-up issues with labels
