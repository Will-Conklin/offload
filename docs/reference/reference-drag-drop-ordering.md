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
  - adr-0003-adhd-focused-ux-ui-guardrails
structure_notes:
  - "Section order: Definition; Schema; Invariants; Examples."
---

# Drag and Drop Ordering

## Definition

Items in lists and plans can be reordered via drag and drop. Structured plans
support nesting by dragging an item onto another item to create a parent-child
relationship.

## Schema

### CollectionItem Ordering

| Field | Type | Meaning |
| --- | --- | --- |
| `CollectionItem.position` | Int | Persistent ordering within a collection. |
| `CollectionItem.parentId` | UUID? | Parent relationship for nested plan items. |

### Collapse State

| Field | Type | Meaning |
| --- | --- | --- |
| `collapseState` | Session-only | Whether a parent shows or hides its children. |

## Invariants

- Reordering updates `CollectionItem.position` and persists the new order.
- Nesting updates `parentId` and is allowed only in structured collections.
- Drag operations stay within a single collection (no cross-collection moves).
- Collapse state is session-scoped and is not persisted.

## Examples

- Reordering a list item updates its position and survives relaunch.
- Dragging a plan item onto another makes it a child and indents it in the list.
