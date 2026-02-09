---
id: plan-item-search-tags
type: plan
status: complete
owners:
  - Will-Conklin
applies_to:
  - capture
  - organize
last_updated: 2026-02-03
related:
  - prd-0005-item-search-tags
  - adr-0003-adhd-focused-ux-ui-guardrails
  - adr-0002-terminology-alignment-for-capture-and-organization
  - design-item-search-tags
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues:
  - https://github.com/Will-Conklin/offload/issues/106
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: Item Search by Text or Tag

## Overview

Add a lightweight search UI for items and tags in Capture and Organize, with tag
chips for scoped searches and minimal disruption to existing flows.

## Goals

- Provide a floating search entry point near Settings.
- Support text and tag search with selectable tag chips.
- Keep search interactions low-friction and dismissible.

## Phases

### Phase 1: UI Entry Point

**Status:** Complete

- [x] Add a search icon to Capture and Organize toolbars.
- [x] Implement the custom floating search bar presentation.

### Phase 2: Querying and Results

**Status:** Complete

- [x] Add repository queries for text and tag matching.
- [x] Integrate search state into view models for Capture and Organize.
  - [x] Ensure tag matching uses `tagLinks` and does not depend on `legacyTags`.

### Phase 3: Tag Chips

**Status:** Complete

- [x] Surface matching tag chips below the search bar.
- [x] Implement selected chip state and scoped filtering.

### Phase 4: QA

**Status:** Complete

- [x] Verify results update as text changes.
- [x] Confirm tag chip selection narrows results.
- [x] Validate layout and interaction on small screens.

## Dependencies

- Design: `design-item-search-tags`.
- ADRs: `adr-0003` and `adr-0002`.
- Repository support for tag and text search.

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Search UI overlaps existing controls | M | Tune placement and spacing per device. |
| Large datasets slow searches | M | Use efficient predicates and throttling. |
| Tag chips overwhelm UI | L | Limit chip count and prioritize matches. |

## User Verification

- [ ] User verification complete.

## Progress

| Date       | Update                                                    |
| ---------- | --------------------------------------------------------- |
| 2026-01-21 | Draft plan created.                                       |
| 2026-02-03 | Phase 1 complete: Search UI implemented for CaptureView.  |
| 2026-02-03 | Phase 2 complete: Search UI implemented for OrganizeView. |
| 2026-02-03 | Phase 3 complete: Tag chip filtering implemented.         |
| 2026-02-03 | Phase 4 complete: All phases finished.                    |
