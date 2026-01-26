---
id: reference-persistent-bottom-tab-bar
type: reference
status: active
owners:
  - Will-Conklin
applies_to:
  - navigation
last_updated: 2026-01-22
related:
  - prd-0002-persistent-bottom-tab-bar
  - design-persistent-bottom-tab-bar
  - plan-persistent-bottom-tab-bar
  - adr-0004-tab-bar-navigation-shell-and-offload-cta
  - adr-0003-adhd-focused-ux-ui-guardrails
depends_on:
  - docs/prds/prd-0002-persistent-bottom-tab-bar.md
  - docs/design/design-persistent-bottom-tab-bar.md
  - docs/plans/plan-persistent-bottom-tab-bar.md
  - docs/adrs/adr-0004-tab-bar-navigation-shell-and-offload-cta.md
  - docs/adrs/adr-0003-adhd-focused-ux-ui-guardrails.md
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Definition; Schema; Invariants; Examples."
---

# Persistent Bottom Tab Bar

## Definition

A persistent bottom tab bar with five destinations and a centered Offload CTA.
This reference codifies the navigation contract from the
[Persistent Bottom Tab Bar PRD](../prds/prd-0002-persistent-bottom-tab-bar.md),
[design doc](../design/design-persistent-bottom-tab-bar.md), and
[implementation plan](../plans/plan-persistent-bottom-tab-bar.md).

## Schema

### Tab Destinations

| Tab | Label | Role | Notes |
| --- | --- | --- | --- |
| Home | Home | Placeholder destination | Placeholder view. |
| Review | Review | Capture inbox | Uses Capture content. |
| Offload | Offload | Primary action | Center CTA that expands to quick capture. |
| Organize | Organize | Collections hub | Uses Organize content. |
| Account | Account | Account root | Settings is accessed from Account. |

### Offload CTA Actions

| Action | Capture Mode | Presentation |
| --- | --- | --- |
| Write | `.write` | Presents `CaptureComposeView` sheet. |
| Voice | `.voice` | Presents `CaptureComposeView` sheet. |

## Invariants

- The tab bar remains visible across navigation stacks.
- The Offload CTA is centered and visually distinct from the other tabs.
- Review uses the existing capture inbox content and remains labeled "Review."
- Account is the root entry for account settings access.
- Quick capture actions always present `CaptureComposeView` with the selected
  `CaptureComposeMode`.
- Navigation follows the guardrails in
  [ADR-0004](../adrs/adr-0004-tab-bar-navigation-shell-and-offload-cta.md) and
  [ADR-0003](../adrs/adr-0003-adhd-focused-ux-ui-guardrails.md).

## Examples

- Selecting Offload → Write presents `CaptureComposeView` in write mode.
- Selecting Offload → Voice presents `CaptureComposeView` in voice mode.
- Selecting Account lands on `AccountView`, with Settings available from there.
