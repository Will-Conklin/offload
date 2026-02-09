---
id: plan-drag-drop-ordering
type: plan
status: complete
owners:
  - Will-Conklin
applies_to:
  - organize
last_updated: 2026-02-04
related:
  - prd-0004-drag-drop-ordering
  - adr-0005-collection-ordering-and-hierarchy-persistence
  - adr-0003-adhd-focused-ux-ui-guardrails
  - design-drag-drop-ordering
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues:
  - https://github.com/Will-Conklin/offload/issues/105
  - https://github.com/Will-Conklin/offload/pull/130
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: Drag and Drop Ordering

## Overview

Deliver drag-and-drop ordering for list and plan items, including nested
hierarchy for structured collections, while maintaining predictable interactions
and persistence.

## Goals

- Enable reordering for lists and plans.
- Support plan hierarchy via drag-to-parent.
- Persist ordering and hierarchy through `CollectionItem.position` and
  `parentId`.

## Phases

### Phase 1: Flat Reordering

**Status:** Complete

- [x] Implement drag-and-drop or `onMove` reordering for unstructured lists.
- [x] Persist new positions via `CollectionItemRepository`.
- [x] Backfill `CollectionItem.position` for existing unstructured list items.

### Phase 2: Plan Nesting

**Status:** Complete

- [x] Add drag-to-parent support for structured collections.
- [x] Update `parentId` and sibling positions after nesting changes.

### Phase 3: UI Feedback

**Status:** Complete

- [x] Add insertion indicators and indentation previews.
- [x] Add expand/collapse affordances for parent items (session-only state).

### Phase 4: QA

**Status:** Pending User Verification

- [ ] Validate ordering persistence across relaunch.
- [ ] Confirm nested items render under parent with indentation.
- [ ] Verify drag gestures do not block scroll behavior.

## Dependencies

- Design: `design-drag-drop-ordering`.
- ADRs: `adr-0005` for persistence, `adr-0003` for interaction guardrails.
- Repository updates to persist positions and parent relationships.

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Drag gestures conflict with scrolling | M | Tune hit targets and gesture priority. |
| Incorrect ordering after nested moves | M | Add deterministic reorder logic and QA. |
| Hidden children cause confusion | M | Provide clear expand/collapse affordances. |

## User Verification

- [ ] User verification complete.

## Progress

| Date       | Update                                                        |
| ---------- | ------------------------------------------------------------- |
| 2026-01-21 | Draft plan created.                                           |
| 2026-02-04 | All phases implemented. PR #130 created for user verification.|
