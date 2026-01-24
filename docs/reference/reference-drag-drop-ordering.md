---
id: reference-drag-drop-ordering
type: reference
status: active
owners:
  - Offload
applies_to:
  - organize
last_updated: 2026-01-22
related:
  - prd-0004-drag-drop-ordering
  - design-drag-drop-ordering
  - plan-drag-drop-ordering
  - adr-0005-collection-ordering-and-hierarchy-persistence
structure_notes:
  - "Section order: Definition; Schema; Invariants; Examples."
---

# Drag & Drop Ordering

## Definition

Drag-and-drop ordering for list and plan items, including hierarchical nesting
for structured collections. This reference formalizes the contracts defined in
the [Drag & Drop Ordering PRD](../prds/prd-0004-drag-drop-ordering.md),
[design doc](../design/design-drag-drop-ordering.md), and
[implementation plan](../plans/plan-drag-drop-ordering.md).

## Schema

### Ordering Fields

| Field | Owner | Purpose |
| --- | --- | --- |
| `CollectionItem.position` | Repository | Persistent ordering within a collection. |
| `CollectionItem.parentId` | Repository | Optional parent relationship for plan hierarchy. |

### Interaction Types

| Interaction | Collection Type | Result |
| --- | --- | --- |
| Reorder within list | List | Update `position` values for items. |
| Reorder within plan | Plan | Update `position` values for siblings. |
| Drop onto item | Plan | Set `parentId` to target item and update positions. |

## Invariants

- Ordering changes persist via `CollectionItem.position`.
- Plan nesting changes persist via `CollectionItem.parentId`.
- Unstructured lists display items ordered by `position`.
- Collapse/expand state is session-only and does not persist.
- Hierarchy and ordering rules align with
  [ADR-0005](../adrs/adr-0005-collection-ordering-and-hierarchy-persistence.md).

## Examples

- Dragging a list item between two items updates its `position` and persists.
- Dropping a plan item onto another assigns its `parentId` to the target item.
- Collapsing a parent hides child items until the session state changes.
