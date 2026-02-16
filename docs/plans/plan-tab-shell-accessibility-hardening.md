---
id: plan-tab-shell-accessibility-hardening
type: plan
status: proposed
owners:
  - Will-Conklin
applies_to:
  - ios
  - ux
  - accessibility
last_updated: 2026-02-16
related:
  - prd-0002-persistent-bottom-tab-bar
  - adr-0003-adhd-focused-ux-ui-guardrails
  - adr-0004-tab-bar-navigation-shell-and-offload-cta
  - design-persistent-bottom-tab-bar
  - plan-ux-accessibility-audit-fixes
depends_on:
  - docs/prds/prd-0002-persistent-bottom-tab-bar.md
  - docs/adrs/adr-0003-adhd-focused-ux-ui-guardrails.md
  - docs/adrs/adr-0004-tab-bar-navigation-shell-and-offload-cta.md
  - docs/design/design-persistent-bottom-tab-bar.md
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: Tab Shell Accessibility Hardening

## Overview

This plan hardens the custom tab shell and floating Offload CTA for consistent
accessibility and adaptability by replacing remaining hardcoded metrics with
theme tokens and adding explicit VoiceOver and Dynamic Type validation.

## Goals

- Route tab shell and CTA spacing/sizing constants through design tokens.
- Verify and improve VoiceOver labels, focus order, and hit targets.
- Validate Dynamic Type and reduced-motion behavior for tab shell interactions.
- Keep UI behavior aligned with ADR-0003 and ADR-0004 guardrails.

## Phases

### Phase 1: Tokenize Tab Shell Metrics

**Status:** Not Started

- [ ] Red:
  - [ ] Add layout snapshot/assertion tests across key device classes and
        dynamic type sizes.
  - [ ] Add tests locking tap-target minimum sizes for tab and CTA actions.
- [ ] Green:
  - [ ] Replace hardcoded tab shell constants (heights, divider sizes, spacers,
        offsets) with `Theme.*` tokens.
  - [ ] Keep current visual hierarchy and interaction affordances.
- [ ] Refactor: group tab-shell-specific tokens under a dedicated theme namespace.

### Phase 2: VoiceOver and Focus Order Hardening

**Status:** Not Started

- [ ] Red:
  - [ ] Add UI/accessibility tests for VoiceOver labels/hints/values on tab and
        CTA actions.
  - [ ] Add traversal-order tests for expanded quick action tray.
- [ ] Green:
  - [ ] Ensure explicit labels/hints/traits for all tab and CTA controls.
  - [ ] Ensure predictable focus order for expanded and collapsed CTA states.
- [ ] Refactor: extract reusable accessibility modifiers for tab-shell controls.

### Phase 3: Dynamic Type and Reduced Motion Validation

**Status:** Not Started

- [ ] Red:
  - [ ] Add validation tests for no clipping/overlap at larger content sizes.
  - [ ] Add tests for reduced-motion animation/transition behavior.
- [ ] Green:
  - [ ] Adjust tab/CTA layout and transitions to maintain readability and
        stability under accessibility settings.
- [ ] Refactor: remove duplicated animation guards and keep a single motion
      policy path.

## Dependencies

- [prd-0002-persistent-bottom-tab-bar](../prds/prd-0002-persistent-bottom-tab-bar.md)
- [adr-0003-adhd-focused-ux-ui-guardrails](../adrs/adr-0003-adhd-focused-ux-ui-guardrails.md)
- [adr-0004-tab-bar-navigation-shell-and-offload-cta](../adrs/adr-0004-tab-bar-navigation-shell-and-offload-cta.md)
- [design-persistent-bottom-tab-bar](../design/design-persistent-bottom-tab-bar.md)

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Tokenization drifts from approved visual behavior | M | Use before/after screenshots and snapshot baselines. |
| Accessibility fixes alter expected gesture flows | M | Pair UI tests with manual VoiceOver walkthrough before merge. |
| Large Dynamic Type causes crowded CTA tray | M | Define explicit fallback spacing and wrapping behavior in token set. |

## User Verification

- [ ] Tab and CTA controls remain easy to use with VoiceOver enabled.
- [ ] Dynamic Type sizes up to accessibility categories avoid clipping/overlap.
- [ ] Reduced Motion setting removes non-essential motion while preserving clarity.
- [ ] Visual style remains consistent with approved tab shell design language.

## Progress

| Date | Update |
| --- | --- |
| 2026-02-16 | Plan created from CODE_REVIEW_2026-02-15 UX/accessibility consistency findings. |
