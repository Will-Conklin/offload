---
id: plan-fix-swipe-to-delete
type: plan
status: uat
owners:
  - Will-Conklin
applies_to:
  - organize
last_updated: 2026-02-17
related:
  - plan-resolve-gesture-conflict
  - plan-drag-drop-ordering
depends_on:
  - plan-drag-drop-ordering
supersedes: []
accepted_by: @Will-Conklin
accepted_at: 2026-02-13
related_issues:
  - https://github.com/Will-Conklin/offload/issues/140
  - https://github.com/Will-Conklin/offload/issues/160
implementation_pr: https://github.com/Will-Conklin/offload/pull/156
structure_notes:
  - "Section order: Overview; Context; Goals; Phases; Dependencies; Risks; User Verification; Progress."
  - "Implementation merged 2026-02-13; UAT pending in issue #160 (CRITICAL: verify gesture conflicts)"
---

# Plan: Fix Swipe-to-Delete in Organize View

## Overview

Restore swipe-to-delete functionality in the Organize feature by porting the working gesture implementation from CaptureItemCard to CollectionDetailItemRows.

## Context

Swipe-to-delete works correctly in CaptureView (implemented in commit f91521d) but is missing from the Organize feature. When CollectionDetailItemRows.swift was created during the view decomposition refactor (commit d9515d1), the swipe gesture was not ported over. The current Organize views only have context menu buttons for delete operations.

This is not a regression of broken functionality, but rather a feature gap where the swipe pattern was never implemented in the refactored Organize views.

### Critical Consideration: Gesture Conflicts

ItemRow is wrapped by DraggableItemRow and HierarchicalItemRow components that already implement `.draggable()` for drag-to-reorder functionality (see plan-drag-drop-ordering). Adding swipe gestures could potentially conflict with this existing drag gesture.

However, the use case differs from the collection card gesture conflict (see plan-resolve-gesture-conflict):

- **Collection cards**: Long-press conflict between drag-to-reorder AND context menu → solved with overlay button
- **Item cards**: Need to differentiate between:
  - **Drag-to-reorder**: Drag in any direction to reposition item
  - **Swipe-to-delete**: Quick horizontal swipe left to delete
  - **Vertical scroll**: Up/down scrolling of the list

**Why swipe is appropriate for items**:

1. **Directional differentiation**: Swipe-to-delete is strictly horizontal left; drag-to-reorder allows any direction
2. **Velocity differentiation**: Swipe is a quick gesture; drag is sustained
3. **Proven pattern**: CaptureItemCard successfully uses swipe without drag conflicts (though Capture doesn't have reordering)
4. **UX consistency**: Items should feel more "fluid" than collections (common iOS pattern)
5. **`.simultaneousGesture()`**: SwiftUI's simultaneous gesture API is designed for this use case

**Risk**: If testing reveals unresolvable conflicts, fallback to overlay button pattern like collection cards.

## Goals

- Port swipe-to-delete gesture from CaptureItemCard to ItemRow component
- Ensure swipe gesture doesn't conflict with existing drag-drop reordering
- Maintain accessibility support with VoiceOver delete actions
- Remove redundant context menu delete button to simplify UI

## Phases

### Phase 1: Port Swipe Gesture

**Status:** Not started

- [ ] Add state variables to ItemRow: `@State private var offset: CGFloat = 0`
- [ ] Add environment variable: `@Environment(\.accessibilityReduceMotion) private var reduceMotion`
- [ ] Add swipe indicator overlay showing trash icon when swiping left
- [ ] Apply `.offset(x: offset)` to card to follow gesture
- [ ] Implement DragGesture with `.simultaneousGesture()` modifier

**Implementation Notes:**

- Only support left-swipe delete (no right-swipe complete action)
- Threshold: -100px to trigger delete
- Use `abs(dx) > abs(dy)` to differentiate horizontal swipe from vertical scroll
- Use spring animation: `.spring(response: 0.3, dampingFraction: 0.7)`
- Respect `reduceMotion` preference

### Phase 2: Test Gesture Conflicts (CRITICAL)

**Status:** Not started

This phase is critical due to existing drag-to-reorder functionality. Test extensively before proceeding to Phase 3.

**Vertical Scroll Testing:**

- [ ] Scroll up/down through item list → no swipe indicators appear
- [ ] Scroll while finger drifts slightly left/right → scroll works, no swipe
- [ ] Verify scroll momentum not interrupted by swipe gesture detection

**Drag-to-Reorder Testing:**

- [ ] Long-press item → drag affordance appears
- [ ] Drag item vertically to new position → reordering works
- [ ] Drag item left/right during reorder → reordering still works (doesn't trigger delete)
- [ ] Drop item → position persists correctly

**Swipe-to-Delete Testing:**

- [ ] Quick horizontal swipe left (< 100px) → card snaps back
- [ ] Quick horizontal swipe left (> 100px) → item deletes
- [ ] Slow horizontal drag left → should NOT trigger delete (differentiates from reorder gesture)
- [ ] Swipe at an angle (not purely horizontal) → verify correct behavior

**Conflict Resolution Testing:**

- [ ] If swipe and drag conflict, document exact scenario
- [ ] If unresolvable conflict found, prepare to pivot to overlay button pattern (see plan-resolve-gesture-conflict)
- [ ] Test on both Plans (structured) and Lists (unstructured) collection types
- [ ] Test with Reduce Motion enabled

### Phase 3: Add Accessibility

**Status:** Not started

- [ ] Add `.accessibilityAction(named: "Delete") { onDelete() }`
- [ ] Remove duplicate "Remove from Collection" from context menu (lines 358-362)
- [ ] Test VoiceOver delete action works correctly

### Phase 4: Documentation

**Status:** Not started

- [ ] Add entry to CLAUDE.md Gotchas if any gesture conflicts discovered
- [ ] Update Progress section in this plan document

## Dependencies

**Files to Modify:**

- `ios/Offload/Features/Organize/CollectionDetailItemRows.swift` (ItemRow struct, lines 306-415)

**Reference Implementation:**

- `ios/Offload/Features/Capture/CaptureItemCard.swift` (working swipe gesture, lines 67-95)

**Related Plans:**

- `plan-drag-drop-ordering.md` - ItemRow wrappers (DraggableItemRow, HierarchicalItemRow) already have `.draggable()`
- `plan-resolve-gesture-conflict.md` - Collection cards use overlay button pattern to avoid gesture conflicts

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| **Swipe conflicts with drag-drop reordering** | **H** | **Critical concern**: Use `.simultaneousGesture()` + directional checks (`abs(dx) > abs(dy)`). Extensive Phase 2 testing required. If unresolvable, pivot to overlay button pattern. |
| Swipe interferes with vertical scroll | M | Only trigger on horizontal movement: `abs(dx) > abs(dy)` |
| Slow horizontal drag triggers delete instead of reorder | M | Consider velocity threshold or minimum distance before triggering swipe indicators |
| Accidental deletions | L | Keep 100px threshold (consistent with Capture) |
| Gesture confusion for new users | L | Visual feedback (trash icon) during swipe |
| Pattern inconsistency with collection cards | L | Collections use button (plan-resolve-gesture-conflict); items use swipe. Acceptable due to different UX needs. |

## User Verification

### Swipe Functionality

- [ ] Swipe left on item shows trash icon
- [ ] Quick swipe > 100px deletes item from collection
- [ ] Swipe < 100px snaps card back to position
- [ ] Trash icon opacity increases with swipe distance

### Gesture Conflict Resolution (Critical)

- [ ] Vertical scroll works without triggering swipe indicators
- [ ] Drag-to-reorder works without triggering delete
- [ ] Long-press + drag for reordering doesn't show trash icon
- [ ] Quick horizontal swipe doesn't interfere with drag affordance
- [ ] No gestures feel "stuck" or unresponsive
- [ ] User can reliably perform all three actions (scroll, reorder, delete) without confusion

### Accessibility & Polish

- [ ] VoiceOver "Delete" action works
- [ ] Reduce Motion respected (uses `.default` animation)
- [ ] Tested on both Plans and Lists collection types
- [ ] Tested on iPhone and iPad simulators
- [ ] Touch targets meet 44pt minimum (trash icon zone)

### Fallback Decision

- [ ] If gesture conflicts unresolved in Phase 2, document decision to use overlay button pattern instead

## Progress

| Date       | Update                     |
| ---------- | -------------------------- |
| 2026-02-10 | Plan created for Bug #140. |
