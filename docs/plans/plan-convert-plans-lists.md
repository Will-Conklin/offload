---
id: plan-convert-plans-lists
type: plan
status: complete
owners:
  - Will-Conklin
applies_to:
  - organize
last_updated: 2026-02-08
related:
  - prd-0003-convert-plans-lists
  - adr-0005-collection-ordering-and-hierarchy-persistence
  - design-convert-plans-lists
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues:
  - https://github.com/Will-Conklin/offload/issues/104
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: Convert Plans and Lists

## Overview

Implement collection conversion actions for plans and lists, including a
confirmation for plan-to-list conversions and hierarchy flattening aligned with
ADR-0005.

## Goals

- Add conversion actions to collections in Organize.
- Preserve items while converting collection structure.
- Warn users before flattening plan hierarchy.

## Phases

### Phase 1: UX and Entry Points

**Status:** Complete

- [x] Add a context menu action on collection cards for conversion.
- [x] Define concise warning copy for plan-to-list conversion.

### Phase 2: Conversion Logic

**Status:** Complete

- [x] Add repository support for toggling `Collection.isStructured`.
- [x] Flatten hierarchy for plan-to-list by clearing `parentId` and preserving
      depth-first order.
- [x] Preserve ordering for list-to-plan conversion.
- [x] Backfill `CollectionItem.position` for unstructured lists to ensure
      consistent ordering post-conversion.

### Phase 3: UI Wiring

**Status:** Complete

- [x] Wire confirmation dialog for plan-to-list conversion.
- [x] Refresh Organize and detail views after conversion.

### Phase 4: QA

**Status:** Complete

- [x] Verify items remain linked after conversion.
- [x] Confirm plan-to-list warning appears only when required.
- [x] Validate ordering after multiple conversions.

## Dependencies

- Design: `design-convert-plans-lists`.
- ADR: `adr-0005` hierarchy and ordering rules.
- Collection and CollectionItem repository updates.

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Hierarchy loss surprises users | H | Require confirmation and clear warning copy. |
| Ordering becomes inconsistent | M | Use deterministic flattening and verify in QA. |
| Conversion fails to refresh UI | M | Ensure list view models reload after updates. |

## User Verification

- [ ] User verification complete.

## Progress

| Date       | Update                                                                                                         |
| ---------- | -------------------------------------------------------------------------------------------------------------- |
| 2026-01-21 | Draft plan created.                                                                                            |
| 2026-02-08 | Marked in progress; repository has `updateIsStructured` and backfill helpers, conversion flow not wired yet.   |
| 2026-02-08 | Phases 1-3 complete: context menu, confirmationDialog, depth-first flattening, position backfill all wired.    |
| 2026-02-08 | Phase 4 QA complete: 8 unit tests for linkage, flattening, backfill, ordering, empty, and gate.                |
