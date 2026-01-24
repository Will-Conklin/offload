---
id: reference-convert-plans-lists
type: reference
status: active
owners:
  - Offload
applies_to:
  - organize
last_updated: 2026-01-22
related:
  - prd-0003-convert-plans-lists
  - design-convert-plans-lists
  - plan-convert-plans-lists
  - adr-0005-collection-ordering-and-hierarchy-persistence
structure_notes:
  - "Section order: Definition; Schema; Invariants; Examples."
---

# Convert Plans ↔ Lists

## Definition

A collection-level conversion action that toggles a collection between plan and
list behavior while preserving items. This reference consolidates the contracts
from the [Convert Plans ↔ Lists PRD](../prds/prd-0003-convert-plans-lists.md),
[design doc](../design/design-convert-plans-lists.md), and
[implementation plan](../plans/plan-convert-plans-lists.md).

## Schema

### Collection Types

| Type | `Collection.isStructured` | Behavior |
| --- | --- | --- |
| List | `false` | Flat ordering by `CollectionItem.position`. |
| Plan | `true` | Hierarchy via `CollectionItem.parentId`. |

### Conversion Actions

| Action | Entry Point | Warning Required |
| --- | --- | --- |
| Plan → List | Collection context menu | Yes |
| List → Plan | Collection context menu | No |

### Conversion Effects

| Conversion | `isStructured` | `parentId` | Ordering |
| --- | --- | --- | --- |
| Plan → List | `false` | Cleared for all items | Persist depth-first order in `position`. |
| List → Plan | `true` | Unchanged (remains nil) | Preserve current list order in `position`. |

## Invariants

- Conversion preserves all items and their association to the collection.
- Plan → list conversion requires a confirmation warning about hierarchy loss.
- Plan → list conversion clears all `parentId` values.
- Ordering is preserved deterministically via `CollectionItem.position`.
- Collection hierarchy and ordering rules follow
  [ADR-0005](../adrs/adr-0005-collection-ordering-and-hierarchy-persistence.md).

## Examples

- A plan with nested items converted to a list results in a flat list ordered by
  a depth-first traversal of the plan hierarchy.
- A list converted to a plan retains the existing order and has no nested items
  until the user adds hierarchy.
