---
id: plan-ios-data-performance-hardening
type: plan
status: uat
owners:
  - Will-Conklin
applies_to:
  - ios
  - performance
  - persistence
last_updated: 2026-02-18
related:
  - prd-0001-product-requirements
  - prd-0007-smart-task-breakdown
  - adr-0005-collection-ordering-and-hierarchy-persistence
depends_on:
  - docs/prds/prd-0001-product-requirements.md
  - docs/adrs/adr-0005-collection-ordering-and-hierarchy-persistence.md
supersedes: []
accepted_by: @Will-Conklin
accepted_at: 2026-02-16
related_issues:
  - https://github.com/Will-Conklin/Offload/issues/213
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: iOS Data and Performance Hardening

## Overview

This plan addresses iOS data-layer performance and storage findings with one
cohesive migration path: O(n) reorder behavior, file-backed attachments with
lazy migration, and typed metadata access with backward compatibility.

## Goals

- Eliminate O(n^2) reorder paths in collection repositories.
- Move attachment storage from inline SwiftData blob fields to file-backed
  storage pointers.
- Replace ad-hoc metadata JSON string handling with typed Codable accessors.
- Preserve existing behavior and data compatibility during migration.

## Phases

Phase completion below reflects implementation status. Plan status remains
`uat` until User Verification is complete.

### Phase 1: Reorder Complexity Refactor

**Status:** Completed

- [x] Red:
  - [x] Add repository tests for large reorder sets in `CollectionRepository`
        and `CollectionItemRepository`.
  - [x] Add tests confirming structured/unstructured ordering behavior remains
        unchanged.
- [x] Green:
  - [x] Replace repeated linear `first(where:)` lookups with dictionary indexes
        keyed by `itemId`.
  - [x] Keep persisted position semantics unchanged.
- [x] Refactor: centralize reorder mapping helpers to avoid duplicated logic.

### Phase 2: File-Backed Attachments (Pre-v1 Hard Cut)

**Status:** Completed

- [x] Red:
  - [x] Add tests for attachment file lifecycle on create/update/delete.
  - [x] Add tests enforcing app-managed attachment path boundaries.
  - [x] Add tests for attachment delete/update cleanup.
- [x] Green:
  - [x] Introduce attachment storage service with file path pointer metadata.
  - [x] Persist attachments as file-backed data and keep references in metadata.
  - [x] Enforce attachment read/delete operations within app-owned storage.
- [x] Refactor:
  - [x] Remove legacy lazy-migration paths and migration-on-appear hooks.
  - [x] Keep display/read paths centralized through repository helpers.

### Phase 3: Typed Metadata Model (Typed Core + Extension Map)

**Status:** Completed

- [x] Red:
  - [x] Add tests for typed metadata encode/decode and unknown key
        round-tripping.
  - [x] Add backward compatibility tests for existing JSON string payloads.
- [x] Green:
  - [x] Define Codable metadata type with core fields plus extension map.
  - [x] Add model/repository accessors that decode once per lifecycle.
- [x] Refactor:
  - [x] Remove duplicated JSONSerialization call sites.
  - [x] Keep compatibility bridge for older metadata values.

## Dependencies

- [prd-0001-product-requirements](../prds/prd-0001-product-requirements.md)
- [prd-0007-smart-task-breakdown](../prds/prd-0007-smart-task-breakdown.md)
- [adr-0005-collection-ordering-and-hierarchy-persistence](../adrs/adr-0005-collection-ordering-and-hierarchy-persistence.md)

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Attachment cleanup failure leaves stale files | M | Treat cleanup as best-effort after successful save and log failures for follow-up cleanup. |
| Reorder refactor changes ordering semantics | M | Lock behavior with pre/post regression tests before optimization. |
| Metadata typing breaks unknown future fields | M | Preserve extension map and round-trip unknown keys in tests. |

## User Verification

- [ ] Reordering remains correct and responsive in large collections.
- [ ] Existing items with attachments remain visible after migration.
- [ ] New attachment create/update/remove flows remain stable.
- [ ] Metadata-driven UI behavior remains unchanged for existing records.

## Progress

| Date | Update |
| --- | --- |
| 2026-02-16 | Plan created from CODE_REVIEW_2026-02-15 iOS performance/data integrity findings. |
| 2026-02-17 | Phase 1 complete: added large-set reorder regression tests, preserved structured/unstructured ordering semantics, and replaced O(n^2) `first(where:)` reorder lookups with shared dictionary-based mapping helpers. |
| 2026-02-17 | Phase 2 complete: switched to pre-v1 hard-cut file-backed attachments, enforced attachment path boundaries, removed lazy migration paths/hooks, and kept repository/UI attachment rendering behavior stable. |
| 2026-02-17 | Follow-up hardening: fixed `updateAttachment` so old-file cleanup failures no longer roll back in-memory state after successful persistence; added regression coverage for cleanup-failure behavior. |
| 2026-02-17 | Phase 3 complete: introduced typed `ItemMetadata` with extension-map round-tripping, replaced ad-hoc JSON metadata handling with cached typed accessors, added repository metadata accessors, and preserved backward compatibility for legacy JSON payloads. |
