---
id: design-persistent-bottom-tab-bar
type: design
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
depends_on:
  - docs/prds/prd-0002-persistent-bottom-tab-bar.md
  - docs/adrs/adr-0004-tab-bar-navigation-shell-and-offload-cta.md
  - docs/adrs/adr-0003-adhd-focused-ux-ui-guardrails.md
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Overview; Architecture; Data Flow; UI Behavior; Testing; Constraints."
---

# Design: Persistent Bottom Tab Bar

## Overview

Implement the five-destination tab shell defined in PRD-0002 and ADR-0004 with a
centered Offload CTA that opens quick capture flows. The design reuses the
existing `MainTabView` and `FloatingTabBar` patterns while expanding to five
destinations and maintaining ADHD-friendly navigation guardrails.

## Architecture

- **Root navigation:** `MainTabView` remains the app shell and hosts a persistent
  custom tab bar anchored to the bottom safe area.
- **Tabs:** Home, Review, Offload (CTA), Organize, Account.
  - Home starts as a placeholder view.
  - Review maps to the current `CaptureView` content and navigation title,
    labeled "Review."
  - Organize continues to render `OrganizeView`.
  - Account tab presents `AccountView`; Settings is reachable from there.
- **Offload CTA:** A center button that triggers quick capture actions by
  setting a `CaptureComposeMode` and presenting `CaptureComposeView` as a sheet.
- **Styling:** Reuse `Theme` tokens and `FloatingTabBar` styling to keep a
  consistent look and safe-area behavior.

## Data Flow

1. User taps the Offload CTA.
2. `MainTabView` sets `quickCaptureMode` to `.write` or `.voice`.
3. A sheet presents `CaptureComposeView` with the selected mode.
4. Capture completion posts `Notification.Name.captureItemsChanged`, keeping
   list views in sync.

## UI Behavior

- The tab bar stays anchored and visible across navigation stacks.
- The Offload CTA appears centered and visually distinct, with two quick actions
  for write and voice.
- The Account tab lands on `AccountView`; Settings remains one tap away from
  Account.
- The Settings icon remains in Capture/Organize toolbars; the Account icon moves
  to the Account tab.
- Tab selection states match the current `Theme` selection highlight rules.

## Testing

- Verify the tab bar stays visible across `NavigationStack` pushes.
- Tap the Offload CTA actions and confirm `CaptureComposeView` appears with the
  correct mode.
- Confirm Account tab opens `AccountView` and Settings is accessible from there.
- Validate safe-area padding on small devices and with Dynamic Type.

## Constraints

- Must follow ADR-0004 for tab destinations and Account root.
- Must preserve ADHD navigation guardrails in ADR-0003.
- Maintain the MainTabView → NavigationStack → sheet flow defined in app entry
  points.
