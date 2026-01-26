---
id: adr-0005-collection-ordering-and-hierarchy-persistence
type: architecture-decision
status: accepted
owners:
  - Will-Conklin
  - ios
applies_to:
  - data-model
  - ordering
  - hierarchy
  - ux
last_updated: 2026-01-22
related:
  - prd-0003-convert-plans-lists
  - prd-0004-drag-drop-ordering
  - adr-0002-terminology-alignment-for-capture-and-organization
depends_on:
  - docs/prds/prd-0003-convert-plans-lists.md
  - docs/prds/prd-0004-drag-drop-ordering.md
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Context; Decision; Consequences; Alternatives Considered; Implementation Notes; References; Revision History."
decision-date: 2026-01-21
decision-makers:
  - Will-Conklin
  - ios
---

# adr-0005: Collection Ordering and Hierarchy Persistence

**Status:** Proposed  
**Decision Date:** 2026-01-21  
**Deciders:** Product, iOS  
**Tags:** data-model, ordering, hierarchy

## Context

PRD-0003 introduces conversions between plans and lists. PRD-0004 introduces
drag-and-drop ordering plus nested items for structured collections. We need to
define how ordering and hierarchy are persisted, and how conversions handle
hierarchical data.

## Decision

- Ordering is persisted via `CollectionItem.position` for both lists and plans.
- Hierarchy is persisted via `CollectionItem.parentId` and is only meaningful
  when `Collection.isStructured = true` (plan UI).
- Plan-to-list conversion flattens hierarchy by removing `parentId` values while
  preserving a deterministic order (depth-first traversal by current order).
- List-to-plan conversion preserves item ordering but introduces no hierarchy.
- Collapsed/expanded state is a session-only UI concern and is not persisted in
  the data model.

## Consequences

- Drag-and-drop operations must update `position` values to keep a stable,
  deterministic order across sessions.
- Plan-to-list conversion is safe for data integrity but loses hierarchy by
  design; users must be warned (PRD-0003).
- Persisted data remains minimal and avoids introducing new state solely for UI
  collapse behavior.

## Alternatives Considered

- Persist collapsed state on `CollectionItem`. Rejected to avoid coupling UI
  state to the core data model.
- Store ordering as a per-collection array separate from `CollectionItem`.
  Rejected due to added synchronization risk.
- Convert plan-to-list by alphabetical or created-date ordering. Rejected in
  favor of preserving visible user order.

## Implementation Notes

- Define a consistent flattening strategy (depth-first by `position`) for plan
  conversion to ensure predictable list order.
- Ensure list reorder and plan reorder use the same persistence rules.

## References

- [prd-0003: Convert Plans ↔ Lists](../prds/prd-0003-convert-plans-lists.md)
- [prd-0004: Drag & Drop Ordering](../prds/prd-0004-drag-drop-ordering.md)
- [adr-0002: Terminology Alignment](./adr-0002-terminology-alignment-for-capture-and-organization.md)

## Revision History

| Version | Date       | Notes            |
| ------- | ---------- | ---------------- |
| 1.0     | 2026-01-21 | Initial proposal |
