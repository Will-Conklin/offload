---
id: design-convert-plans-lists
type: design
status: accepted
owners:
  - Will-Conklin
applies_to:
  - organize
last_updated: 2026-01-22
related:
  - prd-0003-convert-plans-lists
  - adr-0005-collection-ordering-and-hierarchy-persistence
  - adr-0002-terminology-alignment-for-capture-and-organization
depends_on:
  - docs/prds/prd-0003-convert-plans-lists.md
  - docs/adrs/adr-0005-collection-ordering-and-hierarchy-persistence.md
  - docs/adrs/adr-0002-terminology-alignment-for-capture-and-organization.md
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Overview; Architecture; Data Flow; UI Behavior; Testing; Constraints."
---

# Design: Convert Plans ↔ Lists

## Overview

Add a conversion action on collections that toggles between plan and list
behavior while preserving items and following the hierarchy rules in ADR-0005.
Plan → list conversions require an explicit warning because hierarchy will be
flattened.

## Architecture

- **Entry point:** `OrganizeView` collection cards expose a context menu action
  for conversion (long-press).
- **Confirmation UI:** Use `confirmationDialog` for plan → list warnings.
- **Repository update:** Add a `convertCollectionType` method on
  `CollectionRepository` to update `Collection.isStructured` and persist changes
  to `CollectionItem.position` and `CollectionItem.parentId`.
- **Hierarchy rules:** Apply ADR-0005 flattening logic for plan → list, and
  generate positions for list → plan based on current ordering. Unstructured
  lists should use `CollectionItem.position` for ordering (backfill as needed).

## Data Flow

1. User long-presses a collection card and selects Convert.
2. If converting plan → list:
   - Show confirmation dialog describing hierarchy loss.
   - On confirm, clear `parentId` values and persist a depth-first order to
     `position`.
3. If converting list → plan:
   - Set `isStructured = true`.
   - Assign positions based on current list order.
4. Refresh the `OrganizeView` and `CollectionDetailView` lists via repository
   notifications.

## UI Behavior

- Conversion actions appear in the collection card context menu.
- Plan → list conversion shows a concise warning with confirm/cancel actions.
- After conversion, the collection remains in place and its items are preserved.

## Testing

- Convert a plan with nested items to a list and verify hierarchy is flattened.
- Convert a list to a plan and verify item ordering is preserved.
- Ensure conversion does not orphan items or break `CollectionItem` links.
- Confirm the warning shows only for plan → list conversion.

## Constraints

- Must follow ADR-0005 for position and hierarchy persistence.
- Use the canonical terminology from ADR-0002 (`Collection`, `CollectionItem`).
