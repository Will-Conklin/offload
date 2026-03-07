# UAT Checklist

Manual verification tasks for all shipped features. Record results in the Evidence table at the bottom.

Related: GitHub issue #116

---

## Advanced Accessibility

Code complete. Requires on-device validation.

- [ ] VoiceOver + Switch Control: run full checklist in `docs/design.md` (Advanced Accessibility Testing Checklist)
- [ ] Run refactored accessibility tests in CI-capable environment
- [ ] Adjust VoiceOver labels based on QA feedback
- [ ] Complete user verification sign-off

---

## Core Feature Verification

Test on at least one iPhone and one iPad. Use a physical device for voice capture.

- [ ] Text capture CRUD: create, edit content, delete with undo restore
- [ ] Attachments: add photo, verify render, remove and confirm capture intact
- [ ] Tags: add tag, remove tag, confirm list updates
- [ ] Star: star and unstar a capture
- [ ] Follow-up: set and clear a follow-up date
- [ ] Organize — plan: create plan, move capture in, reorder items, confirm order persists
- [ ] Organize — list: create list, move capture in
- [ ] Mark complete: mark plan item complete, confirm completed state
- [ ] Voice capture: run through Voice Capture Testing Checklist in `docs/design.md`
- [ ] Settings: all sections render, external links resolve
- [ ] Persistence: force-quit and relaunch, verify recent changes persist; background and return, verify UI state consistent

---

## New Item Types

- [ ] Compose: 7 type chips appear (Task, Note, Idea, Question, Decision, Concern, Reference) — no "Link" chip
- [ ] Compose: tapping a chip selects it (filled style); tapping again deselects
- [ ] Compose: submitting with **Idea** selected → item appears in CaptureView with "Idea" label
- [ ] Compose: submitting with no type → item appears with no type label
- [ ] Card: type label reads "Idea" / "Note" etc. (not old uppercase style)
- [ ] Filter bar: 7 filter chips appear above the capture list
- [ ] Filter bar: tapping **Idea** → only Idea items shown, chip shows active style
- [ ] Filter bar: tapping active chip again → filter clears, all captures reappear
- [ ] Filter bar: tapping **Note** with no Note items → empty list, no crash
- [ ] Items in collections do not appear in CaptureView under any type filter
- [ ] Typed captures persist correct type across force-quit and relaunch
- [ ] Completing a typed capture removes it from CaptureView regardless of active filter

---

## Accessibility Review

- [ ] VoiceOver on core views: contrast, tap targets, focus order
- [ ] Tab shell + floating CTA: traversal end-to-end
- [ ] Dynamic Type at accessibility sizes: tab shell + CTA quick actions
- [ ] New Item Types — compose chips: VoiceOver reads "Idea type, tap to set capture type" (unselected) and "Idea type, Selected. Tap to remove type." (selected)
- [ ] New Item Types — filter chips: VoiceOver reads "Idea filter" and "Active. Tap to show all types."

---

## Non-functional Launch Gates

All must pass before Release Prep begins.

- [ ] Define and record thresholds: backend p95 latency, iOS startup budget, iOS idle-memory budget, TestFlight crash-free rate
- [ ] Triage and fix issues surfaced from testing phases above; retest affected flows

---

## Evidence

| Date | Device | OS | Build | Tester | Section | Summary |
| ---- | ------ | -- | ----- | ------ | ------- | ------- |
| YYYY-MM-DD | iPhone/iPad | iOS | Debug/Release | Name | Section name | Pass/Fail + notes |
