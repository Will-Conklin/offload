---
id: plan-trailing-gutter-swipe-delete
type: plan
status: uat
owners:
  - TBD
applies_to:
  - capture
  - organize
last_updated: 2026-02-19
related:
  - plan-fix-swipe-to-delete
  - plan-resolve-gesture-conflict
depends_on:
  - plan-fix-swipe-to-delete
supersedes: []
accepted_by: "@Will-Conklin"
accepted_at: 2026-02-18
related_issues:
  - https://github.com/Will-Conklin/Offload/issues/220
  - https://github.com/Will-Conklin/Offload/issues/225
structure_notes:
  - "Section order: Overview; Context; Goals; Phases; Dependencies; Risks; User Verification; Progress."
  - "Implementation phases use TDD slices: red -> green -> refactor."
---

# Plan: Trailing-Gutter Swipe Delete Affordance

## Overview

Introduce a theme-matched, rounded trailing delete affordance that appears in
the right-side gutter (outside card surfaces), aligned with iOS Mail-style
interaction patterns.

## Context

Current swipe-delete visuals render the trash icon on top of card content for
capture and collection item rows. Collection cards in Organize do not currently
support swipe-delete. The desired behavior is a consistent trailing-gutter
affordance across item cards, item rows, and collection cards with safer
deletion for collections.

## Goals

- Move delete affordance from card surface to trailing gutter for swipe-delete
  interactions.
- Keep interaction consistent across Capture, Collection Detail, and Organize
  collection cards.
- Preserve drag-and-drop and scroll behavior with no gesture regressions.
- Require confirmation for collection deletion only.

## Phases

### Phase 1: Shared Swipe Interaction Primitive

**Status:** Completed

- [ ] **Red:** Add unit tests for swipe state transitions (closed, revealed,
  full-swipe delete).
- [ ] **Green:** Implement shared swipe interaction model and threshold
  constants.
- [ ] **Refactor:** Centralize clamp/snap logic and remove duplicated gesture
  math.

### Phase 2: Capture Item Cards (Trailing Gutter Delete)

**Status:** Completed

- [ ] **Red:** Add tests covering left reveal/tap delete/full-swipe delete while
  preserving right-swipe complete.
- [ ] **Green:** Update capture item card rendering to show delete tile in
  trailing gutter.
- [ ] **Refactor:** Extract shared affordance view and align animation behavior
  with Reduce Motion.

### Phase 3: Collection Detail Item Rows

**Status:** Completed

- [ ] **Red:** Add tests for left reveal/tap delete/full-swipe delete and
  close-on-small-swipe behavior.
- [ ] **Green:** Update item row swipe rendering to trailing gutter affordance.
- [ ] **Refactor:** Reuse shared swipe primitive and affordance view.

### Phase 4: Organize Collection Cards + Delete Confirmation

**Status:** Completed

- [ ] **Red:** Add tests for collection delete flow requiring confirmation.
- [ ] **Green:** Add swipe-delete affordance to collection cards; wire
  confirmation dialog before delete.
- [ ] **Refactor:** Consolidate collection delete state handling and refresh
  behavior.

### Phase 5: Validation and Accessibility

**Status:** Completed

- [ ] **Red:** Add tests for accessibility actions and swipe-state tap behavior.
- [ ] **Green:** Ensure VoiceOver delete actions and labels/hints are present on
  all swipe targets.
- [ ] **Refactor:** Normalize semantics and ensure shared behavior across views.

## Dependencies

- Existing swipe behavior in
  `/Users/wconklin/Code/GitHub/Will-Conklin/offload/ios/Offload/Features/Capture/CaptureItemCard.swift`
- Existing row behavior in
  `/Users/wconklin/Code/GitHub/Will-Conklin/offload/ios/Offload/Features/Organize/CollectionDetailItemRows.swift`
- Collection cards in
  `/Users/wconklin/Code/GitHub/Will-Conklin/offload/ios/Offload/Features/Organize/OrganizeCollectionCards.swift`
- Organize delete workflows in
  `/Users/wconklin/Code/GitHub/Will-Conklin/offload/ios/Offload/Features/Organize/OrganizeView.swift`
- Theme tokens in
  `/Users/wconklin/Code/GitHub/Will-Conklin/offload/ios/Offload/DesignSystem/Theme.swift`

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Swipe conflicts with drag reorder gestures | H | Keep horizontal/vertical intent checks and validate across plans/lists/collections. |
| Accidental collection deletion | H | Require confirmation for collection deletes only. |
| Inconsistent behavior across views | M | Use shared swipe logic and shared affordance view. |
| Accessibility regressions | M | Add explicit accessibility actions and verify VoiceOver flows. |

## User Verification

- [ ] Swipe left reveals a rounded delete affordance in the trailing gutter (not
  on-card) for capture items.
- [ ] Swipe left reveals the same trailing-gutter affordance for collection
  detail item rows.
- [ ] Swipe left reveals the same trailing-gutter affordance for organize
  collection cards.
- [ ] Full left swipe deletes capture items and collection detail items
  immediately.
- [ ] Full left swipe on collection cards prompts confirmation before deletion.
- [ ] Tapping revealed delete affordance deletes (or prompts for collections).
- [ ] Vertical scroll and drag reorder remain reliable and responsive.
- [ ] VoiceOver exposes delete actions on all swipe-enabled cards/rows.

## Progress

| Date | Update |
| --- | --- |
| 2026-02-16 | Plan drafted for trailing-gutter swipe-delete behavior and cross-view consistency. |
| 2026-02-19 | PR [#222](https://github.com/Will-Conklin/Offload/pull/222) merged and implementation issue [#220](https://github.com/Will-Conklin/Offload/issues/220) closed; moved plan to `uat` with follow-up verification issue [#225](https://github.com/Will-Conklin/Offload/issues/225). |
