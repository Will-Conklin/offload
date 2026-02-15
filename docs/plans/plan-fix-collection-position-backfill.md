---
id: plan-fix-collection-position-backfill
type: plan
status: in-progress
owners:
  - Will-Conklin
applies_to:
  - organize
  - ordering
  - migration
last_updated: 2026-02-15
related: []
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues:
  - https://github.com/Will-Conklin/Offload/issues/163
  - https://github.com/Will-Conklin/Offload/issues/182
implementation_pr: https://github.com/Will-Conklin/Offload/pull/179
structure_notes:
  - "Section order: Overview; Context; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: Fix Collection Position Backfill

## Overview

Make collection position backfill collision-safe by normalizing all positions in a scope to a contiguous sequence.

## Context

`backfillCollectionPositions` currently assigns `0...n` only to collections missing positions, which can collide with already-assigned positions. Product decision is contiguous ordering and stable visual order.

## Goals

- Prevent duplicate collection positions during backfill.
- Normalize positions for both plans and lists.
- Keep relative visual order stable when normalizing.

## Phases

### Phase 1: Normalize Backfill Strategy

**Status:** Not started

- [ ] Update `backfillCollectionPositions(isStructured:)` to normalize all scoped collections.
- [ ] Preserve current visual order, then rewrite positions as `0...n`.
- [ ] Make normalization idempotent (safe to run repeatedly).

### Phase 2: Ensure New Collections Are Positioned

**Status:** Not started

- [ ] Update collection creation path to assign explicit append position in the relevant scope.
- [ ] Avoid future `nil` positions for newly created collections.

### Phase 3: Integrate with Organize Scope Loading

**Status:** Not started

- [ ] Keep existing `OrganizeView` calls to backfill on load/scope switch.
- [ ] Verify no unexpected reorder when switching plans vs lists.

### Phase 4: Tests

**Status:** Not started

- [ ] Add test: mixed nil + positioned collections normalize without collisions.
- [ ] Add test: colliding existing positions normalize deterministically.
- [ ] Add test: already contiguous positions remain stable after rerun.

## Dependencies

- `ios/Offload/Data/Repositories/CollectionRepository.swift`
- `ios/Offload/Features/Organize/OrganizeView.swift`
- `ios/OffloadTests/CollectionRepositoryTests.swift`

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Normalization changes user-visible ordering unexpectedly | M | Base normalization on currently rendered sort order, then persist |
| Create-path position assignment conflicts with existing records | L | Use same scoped ordering helper as normalization |

## User Verification

- [ ] Existing plans/lists render in expected order after app launch.
- [ ] Switching scopes does not cause random reorder.
- [ ] New plans/lists always appear at the end of their scope.

## Progress

- 2026-02-13: Plan created for issue #163.
- 2026-02-15: Implementation merged in PR #179; opened UAT follow-up issue
  #182.
