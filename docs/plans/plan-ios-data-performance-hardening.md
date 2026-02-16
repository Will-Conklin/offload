---
id: plan-ios-data-performance-hardening
type: plan
status: proposed
owners:
  - Will-Conklin
applies_to:
  - ios
  - performance
  - persistence
last_updated: 2026-02-16
related:
  - prd-0001-product-requirements
  - prd-0007-smart-task-breakdown
  - adr-0005-collection-ordering-and-hierarchy-persistence
depends_on:
  - docs/prds/prd-0001-product-requirements.md
  - docs/adrs/adr-0005-collection-ordering-and-hierarchy-persistence.md
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
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

### Phase 1: Reorder Complexity Refactor

**Status:** Not Started

- [ ] Red:
  - [ ] Add repository tests for large reorder sets in `CollectionRepository`
        and `CollectionItemRepository`.
  - [ ] Add tests confirming structured/unstructured ordering behavior remains
        unchanged.
- [ ] Green:
  - [ ] Replace repeated linear `first(where:)` lookups with dictionary indexes
        keyed by `itemId`.
  - [ ] Keep persisted position semantics unchanged.
- [ ] Refactor: centralize reorder mapping helpers to avoid duplicated logic.

### Phase 2: File-Backed Attachments with Lazy Migration

**Status:** Not Started

- [ ] Red:
  - [ ] Add tests for reading legacy `attachmentData` and migrating on first
        access/save.
  - [ ] Add tests for attachment delete/update cleanup.
- [ ] Green:
  - [ ] Introduce attachment storage service with file path pointer metadata.
  - [ ] Persist new attachments as files and update model references.
  - [ ] Perform lazy migration from inline blobs to file storage.
- [ ] Refactor:
  - [ ] Consolidate image decode and storage utilities.
  - [ ] Ensure errors map cleanly to existing user-facing error flows.

### Phase 3: Typed Metadata Model (Typed Core + Extension Map)

**Status:** Not Started

- [ ] Red:
  - [ ] Add tests for typed metadata encode/decode and unknown key
        round-tripping.
  - [ ] Add backward compatibility tests for existing JSON string payloads.
- [ ] Green:
  - [ ] Define Codable metadata type with core fields plus extension map.
  - [ ] Add model/repository accessors that decode once per lifecycle.
- [ ] Refactor:
  - [ ] Remove duplicated JSONSerialization call sites.
  - [ ] Keep compatibility bridge for older metadata values.

## Dependencies

- [prd-0001-product-requirements](../prds/prd-0001-product-requirements.md)
- [prd-0007-smart-task-breakdown](../prds/prd-0007-smart-task-breakdown.md)
- [adr-0005-collection-ordering-and-hierarchy-persistence](../adrs/adr-0005-collection-ordering-and-hierarchy-persistence.md)

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Data migration bug causes attachment loss | H | Use lazy migration with rollback-safe legacy fallback and backup verification tests. |
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
