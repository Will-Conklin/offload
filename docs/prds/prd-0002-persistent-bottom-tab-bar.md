---
id: prd-0002-persistent-bottom-tab-bar
type: product-requirements
status: accepted
owners:
  - Will-Conklin
applies_to:
  - product
  - navigation
  - ui
last_updated: 2026-01-22
related:
  - adr-0002-terminology-alignment-for-capture-and-organization
  - adr-0003-adhd-focused-ux-ui-guardrails
  - adr-0004-tab-bar-navigation-shell-and-offload-cta
depends_on:
  - docs/adrs/adr-0002-terminology-alignment-for-capture-and-organization.md
  - docs/adrs/adr-0003-adhd-focused-ux-ui-guardrails.md
  - docs/adrs/adr-0004-tab-bar-navigation-shell-and-offload-cta.md
supersedes: []
accepted_by: Offload
accepted_at: 2026-01-22
related_issues: []
structure_notes:
  - "Section order: 1. Product overview; 2. Problem statement; 3. Product goals; 4. Non-goals (explicit); 5. Target audience; 6. Success metrics (after deployment); 7. Core user flows; 8. Functional requirements; 9. Pricing & limits (hybrid model); 10. AI & backend requirements; 11. Data model; 12. UX & tone requirements; 13. Risks & mitigations; 14. Implementation tracking; 15. Open decisions (tracked); 16. Revision history."
---

# Offload — Persistent Bottom Tab Bar PRD

**Date:** 2026-01-22
**Status:** Proposed
**Owner:** Offload

**Related ADRs:**

- [adr-0002: Terminology Alignment](../adrs/adr-0002-terminology-alignment-for-capture-and-organization.md)
- [adr-0003: ADHD-Focused UX/UI Guardrails](../adrs/adr-0003-adhd-focused-ux-ui-guardrails.md)

---

## 1. Product overview

Introduce a persistent bottom tab bar with five destinations and a central
Offload primary action that expands to quick capture options, improving
navigation clarity and emphasizing the core Offload CTA, making it thumb-friendly and optimized for one handed use.

---

## 2. Problem statement

The current bottom navigation and capture affordances are fragmented, making it
harder for users to understand key destinations and the primary action for
quick capture. The primary action is not prominent and there is no tie-in with the idea for the brand.

---

## 3. Product goals

- Provide a consistent, edge-anchored bottom tab bar with five destinations.
- Emphasize Offload as the main CTA via a center-weighted action.
- Preserve quick access to write and voice capture from the CTA.

---

## 4. Non-goals (explicit)

- Redesigning existing feature content (Capture, Organize, Account).
- Introducing new capture types beyond write and voice.

---

## 5. Target audience

- Existing Offload users who rely on fast capture and organization.
- New users onboarding to the core navigation structure.

---

## 6. Success metrics (after deployment)

| Metric ID | Metric | Baseline | Target | Measurement |
| --- | --- | --- | --- | --- |
| M-200 | Tab navigation clarity rating | TBD | +15% | Post-release survey |
| M-201 | Offload CTA usage | TBD | +20% | Analytics event counts |

---

## 7. Core user flows

1. User taps Offload CTA and chooses write or voice capture.
2. User navigates between Home, Review, Organize, and Account tabs.

---

## 8. Functional requirements

| Req ID | Requirement | Priority | User Story |
| --- | --- | --- | --- |
| FR-200 | Provide five tabs: Home, Review, Offload, Organize, Account. | Must | US-200 |
| FR-201 | Offload CTA sits centered and visually distinct. | Must | US-201 |
| FR-202 | Offload CTA expands to write and voice actions. | Must | US-202 |
| FR-203 | Account replaces the icon next to settings. | Should | US-203 |
| FR-204 | Home routes to a placeholder view. | Should | US-204 |

---

## 9. Pricing & limits (hybrid model)

Pricing and limits are deferred; see
[prd-0013: Pricing and Limits](prd-0013-pricing-limits.md).

---

## 10. AI & backend requirements

No new AI or backend requirements.

---

## 11. Data model

No new data model changes required.

---

## 12. UX & tone requirements

- Tab bar remains anchored to the screen edge across app navigation.
- Offload CTA visually breaks the bar and reads as the primary action.
- Write and voice actions mirror existing capture behaviors.

---

## 13. Risks & mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Tab bar conflicts with safe area on small devices | M | Validate layout across device sizes. |
| Offload CTA obscures content | M | Adjust spacing and layering with usability checks. |

---

## 14. Implementation tracking

- Requires updates to navigation structure and tab bar component.
- Reuse existing write and voice capture actions.

---

## 15. Open decisions (tracked)

| Decision | Owner | Status | Notes |
| --- | --- | --- | --- |
| Home placeholder content scope | Product | Open | Determine initial content. |

---

## 16. Revision history

| Version | Date | Notes |
| --- | --- | --- |
| N/A | 2026-01-22 | Initial proposal. |
