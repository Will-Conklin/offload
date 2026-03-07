---
id: plan-fix-atomic-move-to-collection
type: plan
status: uat
owners:
  - Will-Conklin
applies_to:
  - capture
  - organize
  - data-model
last_updated: 2026-02-18
related: []
depends_on: []
supersedes: []
accepted_by: @Will-Conklin
accepted_at: 2026-02-13
related_issues:
  - https://github.com/Will-Conklin/Offload/issues/161
  - https://github.com/Will-Conklin/Offload/issues/212
structure_notes:
  - "Section order: Overview; Context; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: Atomic Move to Collection

## Overview

Make move-to-plan/list behavior all-or-nothing so an item never ends up with a partial state (type changed without a collection link).

## Context

Current move flows perform separate saves for:

1. Item type update
2. Collection link creation

If step 2 fails, step 1 may already be persisted. Product decision is to enforce all-or-nothing behavior.

## Goals

- Ensure move operations commit both mutations in one save boundary.
- Prevent duplicate item-to-collection links.
- Preserve current UX (same sheet actions and error handling).

## Phases

### Phase 1: Repository API for Atomic Move

**Status:** Completed

- [x] Add `ItemRepository.moveToCollectionAtomically(item:collection:targetType:position:) throws`.
- [x] Inside the method, set type + create/update link + save once.
- [x] Roll back context changes on error before rethrowing.

### Phase 2: Migrate Call Sites

**Status:** Completed

- [x] Update move flows in `CaptureSheets.swift` to call the atomic API.
- [x] Remove duplicate multi-save logic from the sheet layer.
- [x] Keep existing `ErrorPresenter` behavior unchanged.

### Phase 3: Guard Against Duplicate Links

**Status:** Completed

- [x] Ensure the atomic API checks for existing `(itemId, collectionId)` links.
- [x] Reuse/update existing link where applicable instead of inserting duplicates.

### Phase 4: Tests

**Status:** Completed

- [x] Add/extend tests for successful atomic move (type + link persisted together).
- [x] Add test that duplicate links are not created.
- [x] Add failure-path test proving no partial state remains.

## Dependencies

- `ios/Offload/Data/Repositories/ItemRepository.swift`
- `ios/Offload/Features/Capture/CaptureSheets.swift`
- `ios/OffloadTests/ItemRepositoryTests.swift`

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Rollback behavior differs from expected SwiftData semantics | M | Add explicit failure-path tests and verify state after thrown errors |
| Existing flows rely on old two-step saves | M | Migrate callsites together and run regression tests |

## User Verification

- [ ] Move an item to an existing plan: type + link both persist.
- [ ] Move an item to a newly created plan/list: no partial state if failure occurs.
- [ ] Repeating move actions does not create duplicate links.

## Progress

- 2026-02-13: Plan created for issue #161.
- 2026-02-14: Implemented repository atomic move API with duplicate-link upsert and rollback behavior.
- 2026-02-14: Migrated capture move flows to atomic API and added repository regression tests.
- 2026-02-14: CLI test configuration stabilized for deterministic simulator runs; full suite passed locally.
