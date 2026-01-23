---
id: reference-item-search-tags
type: reference
status: active
owners:
  - Offload
applies_to:
  - capture
  - organize
last_updated: 2026-01-22
related:
  - prd-0005-item-search-tags
  - design-item-search-tags
  - plan-item-search-tags
  - adr-0003-adhd-focused-ux-ui-guardrails
  - adr-0002-terminology-alignment-for-capture-and-organization
structure_notes:
  - "Section order: Definition; Schema; Invariants; Examples."
---

# Item Search by Text or Tag

## Definition

Search exposes a lightweight query UI in Capture and Organize. Results match
item content and tag names, with matching tags shown as selectable chips to
scope results.

## Schema

### Search State

| Field | Type | Meaning |
| --- | --- | --- |
| `searchText` | String | Current query text. |
| `selectedTagId` | UUID? | Tag filter applied to results. |

### Match Sources

| Entity | Field |
| --- | --- |
| Item | `Item.content` |
| Tag | `Tag.name` |

## Invariants

- Results include items matching `searchText` in item content or tag names.
- Selecting a tag chip scopes results to the selected tag.
- Clearing search resets `searchText` and `selectedTagId`.
- Tag matching uses `tagLinks` relationships, not legacy tag storage.

## Examples

- Query "budget" returns items containing "budget" and items tagged with a
  matching tag.
- Selecting the "Work" tag chip narrows results to items tagged "Work".
