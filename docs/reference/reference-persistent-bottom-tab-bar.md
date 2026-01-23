---
id: reference-persistent-bottom-tab-bar
type: reference
status: active
owners:
  - Offload
applies_to:
  - navigation
last_updated: 2026-01-22
related:
  - prd-0002-persistent-bottom-tab-bar
  - design-persistent-bottom-tab-bar
  - plan-persistent-bottom-tab-bar
  - adr-0004-tab-bar-navigation-shell-and-offload-cta
  - adr-0003-adhd-focused-ux-ui-guardrails
structure_notes:
  - "Section order: Definition; Schema; Invariants; Examples."
---

# Persistent Bottom Tab Bar

## Definition

The app navigation shell uses a persistent bottom tab bar with five destinations
(Home, Review, Offload CTA, Organize, Account). The Offload CTA is centered and
expands to expose quick capture actions.

## Schema

### Tab Destinations

| Destination | Purpose | Notes |
| --- | --- | --- |
| Home | Landing destination. | Placeholder content is acceptable. |
| Review | Capture review list. | Uses the capture content flow. |
| Offload | Primary call-to-action. | Provides Write and Voice quick actions. |
| Organize | Collections overview. | Plans and lists live here. |
| Account | Account root. | Settings remains one tap away. |

### Offload Quick Actions

| Action | Outcome |
| --- | --- |
| Write | Opens the write capture flow. |
| Voice | Opens the voice capture flow. |

## Invariants

- The tab bar remains anchored to the bottom safe area across navigation stacks.
- The Offload CTA stays centered and visually distinct from the other tabs, with
  the main button protruding above the top border of the bar.
- The tab bar remains slim to keep focus on the raised CTA.
- Offload quick actions are limited to Write and Voice, are labeled, and remain
  hidden until the CTA expands.
- Account remains the root for account-related actions, with Settings reachable
  from Account.

## Examples

- A user taps Offload, selects Write, and starts a new capture.
- A user switches from Review to Organize and back without losing tab state.
