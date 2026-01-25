---
id: design-drag-drop-ordering
type: design
status: accepted
owners:
  - Will-Conklin
applies_to:
  - organize
last_updated: 2026-01-22
related:
  - prd-0004-drag-drop-ordering
  - adr-0005-collection-ordering-and-hierarchy-persistence
  - adr-0003-adhd-focused-ux-ui-guardrails
depends_on:
  - docs/prds/prd-0004-drag-drop-ordering.md
  - docs/adrs/adr-0005-collection-ordering-and-hierarchy-persistence.md
  - docs/adrs/adr-0003-adhd-focused-ux-ui-guardrails.md
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Overview; Architecture; Data Flow; UI Behavior; Testing; Constraints."
---

# Design: Drag & Drop Ordering

## Overview

Enable drag-and-drop ordering for list and plan items and support hierarchical
nesting in structured collections. This design aligns with ADR-0005 for
persistent ordering and hierarchy rules, while keeping interactions discoverable
and low-friction.

## Architecture

- **Primary view:** `CollectionDetailView` renders items via `LazyVStack` and
  `ItemRow`; we add drag sources and drop targets at the row level.
- **Drag implementation:** Use SwiftUI drag-and-drop APIs (`draggable`,
  `dropDestination`) for direct manipulation. For flat lists, `List` with
  `onMove` is the fallback when a simple reorder interaction is acceptable per
  Apple SwiftUI guidance.
- **Repository updates:** `CollectionItemRepository` persists `position` and
  `parentId` changes after a drop completes.
- **Ordering for lists:** Unstructured lists use `CollectionItem.position` for
  display ordering; backfill positions when missing.
- **Collapse state:** Keep collapse/expand state in view model only (session
  scoped) per ADR-0005.

## Data Flow

1. User long-presses and drags an item row.
2. The destination row computes a new position and optional `parentId`:
   - List: reorder within the flat array of `CollectionItem`.
   - Plan: drop onto a row to set `parentId` and adjust positions for siblings.
3. Repository updates `CollectionItem.position` (and `parentId` when nested).
4. View model refreshes the sorted list for display.

## UI Behavior

- Show an insertion indicator while dragging between rows.
- When dragging onto a row in a plan, show an indentation preview to indicate
  the new parent.
- Provide a visible expand/collapse affordance for parent items.
- Keep drag gestures responsive and avoid conflicts with scroll.

## Testing

- Reorder items in a list and verify persistence after relaunch.
- Drag a plan item onto another item and confirm it becomes a child.
- Collapse a parent item and ensure child visibility toggles (session-only).
- Convert a plan to a list and verify hierarchy is flattened but ordering
  remains deterministic.

## Constraints

- Persist ordering via `CollectionItem.position` and hierarchy via `parentId`
  (ADR-0005).
- Favor gentle, predictable interactions in line with ADHD guardrails
  (ADR-0003).
