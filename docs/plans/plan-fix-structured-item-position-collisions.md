---
id: plan-fix-structured-item-position-collisions
type: plan
status: uat
owners:
  - Will-Conklin
applies_to:
  - organize
  - capture
  - ordering
last_updated: 2026-02-18
related:
  - plan-drag-drop-ordering
depends_on: []
supersedes: []
accepted_by: @Will-Conklin
accepted_at: 2026-02-15
related_issues:
  - https://github.com/Will-Conklin/Offload/issues/162
  - https://github.com/Will-Conklin/Offload/issues/180
implementation_pr: https://github.com/Will-Conklin/Offload/pull/167
structure_notes:
  - "Section order: Overview; Context; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: Fix Structured Item Position Collisions

## Overview

Eliminate duplicate and unstable item positions in structured collections by replacing count-based position assignment with deterministic position logic and compaction.

## Context

Structured insertion paths currently use collection count as next position. After deletions or mixed ordering states, count-based append can collide with existing `position` values. Product decision is to maintain contiguous positions.

## Goals

- Ensure next insertion position is always unique for a sibling scope.
- Keep positions contiguous after deletions and move operations.
- Preserve drag/drop behavior while stabilizing persisted ordering.

## Phases

### Phase 1: Deterministic Position Helpers

**Status:** Not started

- [ ] Add helper to compute next sibling position as `max(position) + 1`.
- [ ] Add helper to compact sibling positions to `0...n`.
- [ ] Scope helpers by collection and parent (`parentId`) where relevant.

### Phase 2: Replace Count-Based Insertions

**Status:** Not started

- [ ] Replace `collectionItems?.count ?? 0` insertion logic in repository and sheet flows.
- [ ] Use deterministic helper for all structured insertions.
- [ ] Leave unstructured list insertion semantics unchanged.

### Phase 3: Compact on Delete/Mutation Paths

**Status:** Not started

- [ ] Compact affected sibling scope after delete paths in structured collections.
- [ ] Ensure reorder paths still save explicit contiguous positions.

### Phase 4: Tests

**Status:** Not started

- [ ] Add test: delete middle item then append new item -> unique contiguous positions.
- [ ] Add test: duplicate/gapped legacy positions compact deterministically.
- [ ] Add test: child scope compaction (`parentId != nil`) remains stable.

## Dependencies

- `ios/Offload/Data/Repositories/CollectionRepository.swift`
- `ios/Offload/Data/Repositories/CollectionItemRepository.swift`
- `ios/Offload/Features/Capture/CaptureSheets.swift`
- `ios/Offload/Features/Organize/CollectionDetailSheets.swift`
- `ios/OffloadTests/CollectionRepositoryTests.swift`
- `ios/OffloadTests/CollectionItemRepositoryTests.swift`

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Compaction reorders items unexpectedly in edge cases | M | Compact only within affected sibling scope and add deterministic sort fallback |
| Regression in drag/drop ordering | M | Keep reorder logic unchanged and run targeted reorder tests |

## User Verification

- [ ] In structured plans, delete then add keeps stable item order.
- [ ] No duplicate positions appear after repeated reorder/delete/add cycles.
- [ ] Nested item ordering remains correct after child inserts/deletes.

## Progress

- 2026-02-13: Plan created for issue #162.
- 2026-02-15: Implementation merged in PR #167; opened UAT follow-up issue
  #180.
