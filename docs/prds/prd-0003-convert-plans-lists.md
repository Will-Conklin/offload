---
id: prd-0003-convert-plans-lists
type: product-requirements
status: accepted
owners:
  - Will-Conklin
applies_to:
  - product
  - organize
last_updated: 2026-01-22
related:
  - adr-0002-terminology-alignment-for-capture-and-organization
  - adr-0005-collection-ordering-and-hierarchy-persistence
depends_on:
  - docs/adrs/adr-0002-terminology-alignment-for-capture-and-organization.md
  - docs/adrs/adr-0005-collection-ordering-and-hierarchy-persistence.md
supersedes: []
accepted_by: Offload
accepted_at: 2026-01-22
related_issues: []
structure_notes:
  - "Section order: 1. Product overview; 2. Problem statement; 3. Product goals; 4. Non-goals (explicit); 5. Target audience; 6. Success metrics (after deployment); 7. Core user flows; 8. Functional requirements; 9. Pricing & limits (hybrid model); 10. AI & backend requirements; 11. Data model; 12. UX & tone requirements; 13. Risks & mitigations; 14. Implementation tracking; 15. Open decisions (tracked); 16. Revision history."
---

# Offload — Convert Plans ↔ Lists PRD

**Date:** 2026-01-22
**Status:** Proposed
**Owner:** Offload

**Related ADRs:**

- [adr-0002: Terminology Alignment](../adrs/adr-0002-terminology-alignment-for-capture-and-organization.md)

---

## 1. Product overview

Allow users to convert a plan to a list and a list to a plan via a long-press
action on a collection, including a warning when converting a plan to a list
because structure will be lost.

---

## 2. Problem statement

Users create plans and lists without always knowing which structure fits their
needs, but cannot change type later without recreating the collection.

---

## 3. Product goals

- Provide an easy conversion action between plans and lists.
- Protect users from losing plan structure with a clear warning.
- Preserve items during conversion.

---

## 4. Non-goals (explicit)

- Introducing new collection types beyond plan and list.
- Automating structural migration beyond flattening for plan → list.

---

## 5. Target audience

- Users who experiment with plan vs list structure.
- Users who need flexibility as a project evolves.

---

## 6. Success metrics (after deployment)

| Metric ID | Metric | Baseline | Target | Measurement |
| --- | --- | --- | --- | --- |
| M-210 | Conversions completed | TBD | 100+ | Analytics event counts |
| M-211 | Conversion-related support reports | TBD | -20% | Support logs |

---

## 7. Core user flows

1. User long-presses a plan and selects "Convert to list."
2. User reviews warning about structure loss and confirms.
3. User long-presses a list and selects "Convert to plan."

---

## 8. Functional requirements

| Req ID | Requirement | Priority | User Story |
| --- | --- | --- | --- |
| FR-210 | Long-press on a collection shows a convert action. | Must | US-210 |
| FR-211 | Plan → list conversion shows a warning and requires confirmation. | Must | US-211 |
| FR-212 | List → plan conversion completes without warning. | Should | US-212 |
| FR-213 | Items remain attached to the collection after conversion. | Must | US-213 |

---

## 9. Pricing & limits (hybrid model)

Pricing and limits are deferred; see
[prd-0013: Pricing and Limits](prd-0013-pricing-limits.md).

---

## 10. AI & backend requirements

No new AI or backend requirements.

---

## 11. Data model

Collection type is represented by existing structure/list metadata; conversion
must preserve the collection and its items.

---

## 12. UX & tone requirements

- Warning copy should be concise and clear about structure loss.
- Conversion should feel reversible and low friction.

---

## 13. Risks & mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Users accidentally lose structured hierarchy | H | Require explicit confirmation for plan → list. |
| Confusion about plan vs list behavior | M | Provide short helper text in confirmation. |

---

## 14. Implementation tracking

- Requires collection action menu updates and conversion logic.

---

## 15. Open decisions (tracked)

| Decision | Owner | Status | Notes |
| --- | --- | --- | --- |
| Warning copy finalization | Product | Open | Needs copy review. |

---

## 16. Revision history

| Version | Date | Notes |
| --- | --- | --- |
| N/A | 2026-01-22 | Initial proposal. |
