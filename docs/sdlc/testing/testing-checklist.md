<!--
Intent: Track execution of the master plan testing checklist and capture
evidence for remediation and UI/UX validation.
-->

# Offload Testing Checklist

## Agent Navigation

- Overview: Purpose, Status Summary
- Checklist: Phase 1-3, UI Foundation, Components, Animation, ADHD,
  Accessibility, Integration
- Evidence: Run Log

## Purpose

Use this checklist to mark testing progress and capture evidence for the
remediation phases, UI foundation, and end-to-end workflows. Items align with
`docs/sdlc/plans/master-plan.md` Appendix B.

## Status Summary

- Started: 2026-01-09
- Owner: TBD
- Environment: iPhone 16 Pro Simulator (iOS 18.3.1)

## Run Log

| Date | Scope | Device/OS | Result | Notes |
| --- | --- | --- | --- | --- |
| 2026-01-09 | Phase 1-3 | iPhone 16 Pro Simulator (iOS 18.3.1) | Pending | Initial run |

## Phase 1-3 Remediation Testing

### Critical Bug Verification

#### Run Evidence

| Date | Scenario | Result | Notes |
| --- | --- | --- | --- |
| 2026-01-09 | Start | In progress | Begin critical bug verification |
| 2026-01-09 | Toast cancellation | Skipped | No in-app trigger wired yet |
| 2026-01-09 | Delete race conditions | Pass | Rapid deletes in Captures, no crash or reappearing items |
| 2026-01-09 | Error suppressions | Pass | No try? usages found in ios/Offload (excluding tests) |
| 2026-01-09 | Repository predicates | Pass | Predicates used across repositories; fetchAllSuggestions uses full fetch due to SwiftData limitation |
| 2026-01-09 | Relationships | Pass | @Relationship declarations verified across models |
| 2026-01-09 | URL validation | Pass | SettingsView validates HTTPS/host/length; only static URL force unwraps remain |
| 2026-01-09 | MainActor sync | Pass | CaptureWorkflowService marked @MainActor with guarded state |
| 2026-01-09 | API endpoint validation | Pass | SettingsView handleSave enforces HTTPS and host validation |

- [ ] Toast cancellation works (rapid show, auto-dismiss, manual dismiss)
- [x] No race conditions in delete operations
- [x] All 21 error suppressions properly handled
- [x] Repository queries use predicates (verify via code review)
- [x] Relationships properly declared (verify models)
- [x] No force unwraps crash (test URL validation)
- [x] MainActor synchronization correct (test concurrent captures)
- [x] Input validation prevents invalid API endpoints

### Performance Validation

#### Run Evidence

| Date | Scenario | Result | Notes |
| --- | --- | --- | --- |
| 2026-01-09 | Benchmarks | Skipped | No benchmark tooling available yet |

- [ ] Query benchmarks at 100 records: <10ms
- [ ] Query benchmarks at 1000 records: <100ms
- [ ] Query benchmarks at 10000 records: <1000ms
- [ ] Memory usage stable during bulk operations
- [ ] No memory leaks detected (Instruments)

## UI Foundation Testing

### Visual Consistency

- [ ] Light mode: All screens render correctly
- [ ] Dark mode: All screens render correctly
- [ ] Glass effects visible but subtle
- [ ] Corner radius consistent throughout
- [ ] Spacing consistent (no hardcoded values visible)
- [ ] Shadows provide appropriate depth
- [ ] Gradients render correctly

### Device Compatibility

- [ ] iPhone SE (small screen) - all content accessible
- [ ] iPhone 14/15 Pro (standard) - optimal layout
- [ ] iPhone 15 Pro Max (large) - no wasted space
- [ ] Portrait orientation works
- [ ] Landscape orientation works (if supported)

## Component Testing

### Badge Component

- [ ] Category badges render with correct colors
- [ ] Status badges show appropriate states
- [ ] Icons display when provided
- [ ] Text truncates gracefully for long labels
- [ ] Tappable area meets 44pt minimum

### Expandable Card

- [ ] Tap to expand works smoothly
- [ ] Animation is spring-based and smooth
- [ ] Collapsed state shows 2-line preview
- [ ] Expanded state shows full content
- [ ] No layout jumping during expansion

### Other Components

- [ ] Pill selector scrolls horizontally
- [ ] Progress ring animates smoothly
- [ ] Progress bar shows accurate progress
- [ ] Loading skeletons shimmer correctly
- [ ] All components respect color scheme

## Animation Testing

### Performance

- [ ] Spring animations run at 60fps
- [ ] No frame drops on button presses
- [ ] Celebration animations smooth
- [ ] Glass effects do not degrade scrolling
- [ ] Toast animations smooth

### Accessibility

- [ ] Reduced motion respected (animations disabled)
- [ ] User can toggle animations in settings
- [ ] No flashing content (seizure risk)
- [ ] Animations enhance, do not distract

## ADHD Feature Testing

### Visual Timeline

- [ ] Renders with 0 captures correctly (empty state)
- [ ] Renders with 50 captures correctly
- [ ] Renders with 100+ captures correctly (performance)
- [ ] Horizontal scrolling is smooth
- [ ] Tap to view capture details works
- [ ] Color coding is clear and consistent
- [ ] Time labels are readable at all sizes

### Cognitive Load Assessment (User Testing)

- [ ] Timeline reduces time blindness (feedback)
- [ ] Next up indicators not anxiety-inducing (feedback)
- [ ] Completion animations feel rewarding (feedback)
- [ ] Settings allow adequate customization
- [ ] Features can be turned off easily
- [ ] Overall cognitive load feels manageable

## Accessibility Testing

### Run Evidence

| Date | Scenario | Result | Notes |
| --- | --- | --- | --- |
| 2026-01-09 | Contrast + Dynamic Type | Pending | Visual QA not run yet |

### VoiceOver

- [ ] All screens navigable with VoiceOver (pending visual QA)
- [ ] All buttons have descriptive labels (pending visual QA)
- [ ] Form inputs announced correctly (pending visual QA)
- [ ] Lists read items in logical order (pending visual QA)
- [ ] Modals announced properly (pending visual QA)
- [ ] Navigation hints are helpful (pending visual QA)

### Contrast

- [ ] Text on backgrounds meets WCAG AA (4.5:1) (pending visual QA)
- [ ] Badge colors meet minimum contrast (pending visual QA)
- [ ] Glass effects do not obscure text (pending visual QA)
- [ ] Focus indicators visible and clear (pending visual QA)

### Dynamic Type

- [ ] Extra Small text readable (pending visual QA)
- [ ] Small text readable (pending visual QA)
- [ ] Medium (default) optimal (pending visual QA)
- [ ] Large text does not break layout (pending visual QA)
- [ ] Extra Large text does not clip (pending visual QA)
- [ ] Accessibility sizes (XXL, XXXL) work (pending visual QA)

## Integration Testing

### Run Evidence

| Date | Scenario | Result | Notes |
| --- | --- | --- | --- |
| 2026-01-09 | End-to-end flows | Pending | Visual QA not run yet |

### End-to-End Flows

- **Manual Test Script**
  - Capture (text) → View in Captures → Delete
    1. Open Captures tab.
    2. Tap Capture, enter text, Save.
    3. Confirm entry appears in list.
    4. Swipe to delete, confirm it disappears.
  - Capture (voice) → Transcription → View → Edit
    1. Open Capture, tap mic, speak, stop recording.
    2. Confirm transcription appears in text field.
    3. Save, then open Captures and confirm entry content.
  - Create Plan → Add Tasks → Mark Complete → Archive
    1. Open Organize, create a new Plan.
    2. Add two tasks, mark one complete.
    3. Confirm completed task appears in Completed section.
  - Create List → Add Items → Check Off → Delete
    1. Open Organize, create a new List.
    2. Add two items, check one off.
    3. Delete an item and confirm it disappears.
  - Settings changes persist across app restarts
    1. Toggle ADHD Support settings.
    2. Force close app, reopen, confirm settings persist.

- [ ] Capture (text) → View in Captures → Delete
- [ ] Capture (voice) → Transcription → View → Edit
- [ ] Create Plan → Add Tasks → Mark Complete → Archive
- [ ] Create List → Add Items → Check Off → Delete
- [ ] Settings changes persist across app restarts

### Error Handling

- [ ] Network errors display toast
- [ ] Validation errors show inline
- [ ] Toast notifications appear/dismiss correctly
- [ ] Retry actions work
- [ ] Data rollback on error works
