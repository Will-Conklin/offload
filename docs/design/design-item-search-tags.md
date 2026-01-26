---
id: design-item-search-tags
type: design
status: accepted
owners:
  - Will-Conklin
applies_to:
  - capture
  - organize
last_updated: 2026-01-22
related:
  - prd-0005-item-search-tags
  - adr-0003-adhd-focused-ux-ui-guardrails
  - adr-0002-terminology-alignment-for-capture-and-organization
depends_on:
  - docs/prds/prd-0005-item-search-tags.md
  - docs/adrs/adr-0003-adhd-focused-ux-ui-guardrails.md
  - docs/adrs/adr-0002-terminology-alignment-for-capture-and-organization.md
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Overview; Architecture; Data Flow; UI Behavior; Testing; Constraints."
---

# Design: Item Search by Text or Tag

## Overview

Add a lightweight search affordance near Settings that reveals a floating search
bar. Search matches `Item.content` and related `Tag.name` values, and exposes
matching tags as selectable chips for tag-scoped searches.

## Architecture

- **Search entry:** Add a search icon next to Settings in Capture and Organize
  toolbars.
- **Search UI:** A custom floating search bar appears below the icon to match
  the PRD placement and interaction.
- **Search state:** A view model stores `searchText` and `selectedTagId`.
- **Querying:** Repository methods search `Item.content` and `Item.tags` via
  SwiftData predicates, returning filtered lists for Capture and Organize views.
  Tag matches use `tagLinks` only (no `legacyTags`).
- **Tag chips:** Render a horizontal chip row below the search field using
  existing tag styling components.

## Data Flow

1. User taps the search icon to reveal the search bar.
2. Typing updates `searchText` and triggers a query for matching items.
3. Matching tags are computed from results; selecting a chip sets
   `selectedTagId` and scopes results to that tag.
4. Clearing the search resets `searchText` and `selectedTagId`.

## UI Behavior

- Search bar anchors below the top-right icon and spans roughly two-thirds of
  the view width.
- Tag chips follow current tag styling and show a selected state when active.
- Search remains non-blocking; users can dismiss quickly to resume normal flow.

## Testing

- Search by text and verify results update as the user types.
- Select a tag chip and confirm results are scoped to that tag.
- Clear the search and ensure the full list returns.
- Validate placement across device sizes and with Dynamic Type.

## Constraints

- Follow ADHD guardrails: low-friction, non-blocking UI (ADR-0003).
- Use canonical terminology (`Item`, `Tag`) from ADR-0002.
