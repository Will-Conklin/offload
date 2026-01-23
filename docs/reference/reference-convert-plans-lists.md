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
  - adr-0002-terminology-alignment-for-capture-and-organization
structure_notes:
  - "Section order: Definition; Schema; Invariants; Examples."
---

# Convert Plans and Lists

## Definition

Collections can be converted between plans (structured) and lists
(unstructured) while preserving the collection and its items. Plan-to-list
conversions require a warning because hierarchy is flattened.

## Schema

### Collection Structure

| Field | Type | Meaning |
| --- | --- | --- |
| `Collection.isStructured` | Bool | `true` for plans, `false` for lists. |

### CollectionItem Ordering

| Field | Type | Meaning |
| --- | --- | --- |
| `CollectionItem.position` | Int | Deterministic ordering within a collection. |
| `CollectionItem.parentId` | UUID? | Parent relationship for structured plans. |

## Invariants

- Conversion does not create a new collection; it updates the existing one.
- Items remain attached to the collection after conversion.
- Plan-to-list conversion clears all `parentId` values and preserves ordering
  via `position`.
- List-to-plan conversion sets `isStructured = true` and preserves the current
  item ordering.
- A confirmation warning is required only for plan-to-list conversion.

## Examples

- A plan with nested items converts to a flat list with the same items in a
  deterministic order.
- A list converts to a plan without losing item order.
