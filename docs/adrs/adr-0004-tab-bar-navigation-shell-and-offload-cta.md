---
id: adr-0004-tab-bar-navigation-shell-and-offload-cta
type: architecture-decision
status: accepted
owners:
  - Will-Conklin
  - ios
applies_to:
  - navigation
  - ux
  - ui
  - architecture
last_updated: 2026-01-22
related:
  - prd-0002-persistent-bottom-tab-bar
  - adr-0003-adhd-focused-ux-ui-guardrails
depends_on:
  - docs/prds/prd-0002-persistent-bottom-tab-bar.md
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Context; Decision; Consequences; Alternatives Considered; Implementation Notes; References; Revision History."
decision-date: 2026-01-21
decision-makers:
  - Will-Conklin
  - ios
---

# adr-0004: Tab Bar Navigation Shell and Offload CTA

**Status:** Proposed  
**Decision Date:** 2026-01-21  
**Deciders:** Product, iOS  
**Tags:** navigation, ux, ui

## Context

PRD-0002 proposes a persistent bottom tab bar with a centered Offload CTA that
expands to quick capture actions. We need an explicit navigation decision that
aligns with ADHD-focused guardrails and clarifies how Settings remains one tap
away.

## Decision

Adopt a five-destination navigation shell with a persistent bottom tab bar:
Home, Review, Offload (CTA), Organize, Account. The Offload CTA is centered and
visually distinct, expanding to quick write and voice capture actions. The
Account tab lands on AccountView, with Settings accessible from there.

## Consequences

- The main shell shifts to five destinations, requiring a custom tab bar
  implementation that supports a centered CTA.
- Account remains one tap via the Account tab root, preserving ADHD-focused
  navigation predictability; Settings stays close to AccountView.
- Capture entry points remain consistent with guardrails: capture actions open
  as sheets while editing flows remain full-screen.

## Alternatives Considered

- Keep the existing tab bar and add a floating capture button. Rejected because
  it de-emphasizes Offload as the primary CTA and weakens destination clarity.
- Replace the Account tab with Settings. Rejected to keep Account-related
  surfaces grouped and extensible.
- Keep four tabs and move Review or Organize into menus. Rejected because it
  increases navigation depth and reduces one-tap access.

## Implementation Notes

- Use a custom tab bar component to support the centered CTA and safe-area
  layout.
- Ensure the Offload CTA expands into quick actions that reuse existing capture
  flows.

## References

- [prd-0002: Persistent Bottom Tab Bar](../prds/prd-0002-persistent-bottom-tab-bar.md)
- [adr-0003: ADHD-Focused UX/UI Guardrails](./adr-0003-adhd-focused-ux-ui-guardrails.md)

## Revision History

| Version | Date       | Notes            |
| ------- | ---------- | ---------------- |
| 1.0     | 2026-01-21 | Initial proposal |
