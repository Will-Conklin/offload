---
id: plan-persistent-bottom-tab-bar
type: plan
status: accepted
owners:
  - Will-Conklin
applies_to:
  - navigation
last_updated: 2026-01-22
related:
  - prd-0002-persistent-bottom-tab-bar
  - adr-0004-tab-bar-navigation-shell-and-offload-cta
  - adr-0003-adhd-focused-ux-ui-guardrails
  - design-persistent-bottom-tab-bar
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; Progress."
---

# Plan: Persistent Bottom Tab Bar

## Overview

Execute the navigation shell update described in PRD-0002 and the design doc by
expanding `MainTabView` to five destinations with a centered Offload CTA, while
preserving ADHD-friendly navigation patterns.

## Goals

- Ship a persistent tab bar with Home, Review, Offload, Organize, Account.
- Ensure Review uses the current Capture content with updated labeling.
- Preserve capture quick actions and Account access patterns.

## Phases

### Phase 1: UX Alignment

**Status:** Not Started

- [ ] Confirm tab labels, icon assets, and placeholder content for Home.
- [ ] Map Review to `CaptureView` content and navigation title labeled “Review”.
- [ ] Confirm Account tab root and Settings navigation path.

### Phase 2: Tab Shell Implementation

**Status:** Not Started

- [ ] Update `MainTabView.Tab` enum and `TabContent` routing for five tabs.
- [ ] Extend `FloatingTabBar` layout to support five destinations and the CTA.
- [ ] Update quick capture actions to match the Offload CTA placement.
- [ ] Ensure Account tab launches `AccountView`.
- [ ] Remove the Account icon from Capture/Organize toolbars while preserving
      the Settings icon.

### Phase 3: QA and Polish

**Status:** Not Started

- [ ] Verify safe-area behavior across device sizes and orientations.
- [ ] Validate dynamic type and icon contrast in light/dark themes.
- [ ] Confirm tab state retention across navigation stacks and sheets.

## Dependencies

- Design: `design-persistent-bottom-tab-bar`.
- ADRs: `adr-0004` and `adr-0003`.
- Icon assets and theme updates (if required by the new tab layout).

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Tab bar overlaps content on small devices | M | Validate safe-area spacing and inset behavior. |
| Capture affordances feel less prominent | M | Preserve CTA size/contrast and quick actions. |
| Navigation regressions in existing flows | M | Smoke-test Capture/Organize navigation stacks. |

## Progress

| Date       | Update                |
| ---------- | --------------------- |
| 2026-01-21 | Draft plan created.   |
