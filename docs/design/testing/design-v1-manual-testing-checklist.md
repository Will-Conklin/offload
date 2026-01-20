---
id: design-v1-manual-testing-checklist
type: design
status: active
owners:
  - Offload
applies_to:
  - testing
  - v1-release
last_updated: 2026-01-19
related:
  - plan-v1-roadmap
  - design-voice-capture-testing-guide
structure_notes:
  - "Section order: Purpose; Scope; Preconditions; Checklist; Evidence; Revision history."
  - "Keep top-level sections: Purpose; Scope; Preconditions; Checklist; Evidence; Revision history."
---

# V1 Manual Testing Checklist

## Purpose

Provide a lightweight, repeatable manual checklist for v1 readiness.

## Scope

- Manual-only v1 features (no AI flows, no pagination, no advanced accessibility
  features).
- Core capture, organize, and settings flows on iPhone and iPad.
- Voice capture steps reference the dedicated voice capture testing guide.

## Preconditions

- Fresh install or cleared local data.
- Test on at least one iPhone and one iPad.
- Use a physical device for voice capture.
- Logged into local-only mode (no backend required).

## Checklist

### Capture (Text)

- [ ] Create a text capture from the main entry point.
- [ ] Confirm it appears in the capture list immediately.
- [ ] Edit the capture content and verify the update persists.
- [ ] Delete a capture and confirm undo restores it.

### Capture (Attachments)

- [ ] Add a photo attachment to a capture and verify it renders.
- [ ] Remove the attachment and confirm the capture remains intact.

### Tags, Star, Follow-Up

- [ ] Add a tag, then remove it, and confirm the list updates.
- [ ] Star and unstar a capture.
- [ ] Set and clear a follow-up date.

### Organize (Plans and Lists)

- [ ] Create a plan (structured collection).
- [ ] Create a list (unstructured collection).
- [ ] Move a capture into a plan and verify it appears in order.
- [ ] Move a capture into a list and verify it appears in the list.
- [ ] Reorder items within a plan and confirm order persists.
- [ ] Mark a plan item complete and confirm it moves to completed state.

### Voice Capture

- [ ] Run through the steps in
  [Voice Capture Testing Guide](./design-voice-capture-testing-guide.md).

### Settings

- [ ] Open Settings and verify all sections render.
- [ ] Open each external link and confirm it resolves.

### Persistence

- [ ] Force quit and relaunch; verify recent changes persist.
- [ ] Background the app and return; verify UI state is consistent.

### Accessibility (Baseline)

- [ ] Enable Dynamic Type (Large/Extra Large) and verify layout stability.
- [ ] Enable Reduce Motion and verify animations are minimized.
- [ ] Enable VoiceOver and confirm core controls have labels.

## Evidence

Record results for each run:

| Date | Device | OS | Build | Tester | Summary |
| ---- | ------ | -- | ----- | ------ | ------- |
| YYYY-MM-DD | iPhone | iOS | Debug/Release | Name | Pass/Fail + notes |

## Revision history

| Version | Date | Notes |
| ------- | ---------- | ----- |
| 1.0 | 2026-01-19 | Initial checklist |
