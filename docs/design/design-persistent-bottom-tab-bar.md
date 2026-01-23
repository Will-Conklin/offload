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
structure_notes:
  - "Section order: Overview; Architecture; Data Flow; UI Behavior; Testing; Constraints."
---

# Design: Persistent Bottom Tab Bar

## Overview

Implement the five-destination tab shell defined in PRD-0002 and ADR-0004 with a
centered Offload CTA that expands to reveal quick capture actions. The design reuses the
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

1. User taps the Offload CTA to reveal quick actions.
2. User selects Write or Voice.
3. `MainTabView` sets `quickCaptureMode` to `.write` or `.voice`.
4. A sheet presents `CaptureComposeView` with the selected mode.
5. Capture completion posts `Notification.Name.captureItemsChanged`, keeping
   list views in sync.

## UI Behavior

- The tab bar stays anchored and visible across navigation stacks.
- The Offload CTA appears centered and visually distinct; the main button
  protrudes above the top border of the bar, and the CTA expands to reveal
  labeled Write and Voice quick actions.
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
