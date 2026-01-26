---
id: prd-0013-pricing-limits
type: product-requirements
status: proposed
owners:
  - Will-Conklin
applies_to:
  - product
  - ai
  - pricing
last_updated: 2026-01-25
related:
  - prd-0001-product-requirements
depends_on:
  - docs/prds/prd-0001-product-requirements.md
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: 1. Product overview; 2. Problem statement; 3. Product goals; 4. Non-goals (explicit); 5. Target audience; 6. Success metrics; 7. Core user flows; 8. Functional requirements; 9. Pricing & limits; 10. AI & backend requirements; 11. Data model; 12. UX & tone requirements; 13. Risks & mitigations; 14. Implementation tracking; 15. Open decisions; 16. Revision history."
---

# Offload — Pricing and Limits PRD

**Date:** 2026-01-25
**Status:** Proposed
**Owner:** Offload

**Related PRDs:**

- [prd-0001: Product Requirements](prd-0001-product-requirements.md)

---

## 1. Product overview

Consolidate pricing, limits, and monetization guidance in a single document.
This PRD is deferred; details below are placeholders and not yet approved.

---

## 2. Problem statement

Pricing and limits are scattered across feature PRDs, making it hard to manage
and update monetization decisions consistently.

---

## 3. Product goals

- Centralize all pricing and limit decisions in one PRD
- Avoid coupling pricing decisions to feature requirements until approved
- Provide a single source of truth for AI usage limits once finalized

---

## 4. Non-goals (explicit)

- No pricing decisions are finalized in this version
- No changes to feature scope based on pricing
- No implementation requirements until pricing is approved

---

## 5. Target audience

- Product and business stakeholders
- Engineering leads responsible for usage enforcement

---

## 6. Success metrics

- TBD (deferred with pricing decisions)

---

## 7. Core user flows

- TBD (deferred with pricing decisions)

---

## 8. Functional requirements

- TBD (deferred with pricing decisions)

---

## 9. Pricing & limits (hybrid model)

> **Status:** Deferred. Pricing tiers, limits, and enforcement are not defined
> yet. This section is intentionally blank until pricing decisions are
> approved.

---

## 10. AI & backend requirements

- Deferred; pricing enforcement details live in section 9 and require future
  ADR/design work.

---

## 11. Data model

- TBD (deferred with pricing decisions)

---

## 12. UX & tone requirements

- Ensure limit messaging is non-judgmental and shame-free
- Emphasize user control and avoid pressure language

---

## 13. Risks & mitigations

| Risk                   | Mitigation                      |
| ---------------------- | ------------------------------- |
| Conflicting limits     | Single source of truth in PRD   |
| Premature enforcement  | Defer implementation to design  |
| User frustration       | Gentle messaging and clear info |

---

## 14. Implementation tracking

- Deferred until pricing decisions are approved

---

## 15. Open decisions (tracked)

| Decision                   | Status | Notes                             |
| -------------------------- | ------ | --------------------------------- |
| Paid tier soft cap numbers | Open   | To be defined                     |
| Free tier AI action counts | Open   | To be defined                     |
| AI action definition       | Open   | Needs formal definition           |
| Enforcement approach       | Open   | Cloud vs on-device reconciliation |

---

## 16. Revision history

| Version | Date | Notes |
| --- | --- | --- |
| N/A | 2026-01-25 | Initial placeholder document |
