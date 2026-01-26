---
id: prd-0004-drag-drop-ordering
type: product-requirements
status: accepted
owners:
  - Will-Conklin
applies_to:
  - product
  - organize
  - ui
last_updated: 2026-01-22
related:
  - adr-0002-terminology-alignment-for-capture-and-organization
  - adr-0003-adhd-focused-ux-ui-guardrails
  - adr-0005-collection-ordering-and-hierarchy-persistence
depends_on:
  - docs/adrs/adr-0002-terminology-alignment-for-capture-and-organization.md
  - docs/adrs/adr-0003-adhd-focused-ux-ui-guardrails.md
  - docs/adrs/adr-0005-collection-ordering-and-hierarchy-persistence.md
supersedes: []
accepted_by: Offload
accepted_at: 2026-01-22
related_issues: []
structure_notes:
  - "Section order: 1. Product overview; 2. Problem statement; 3. Product goals; 4. Non-goals (explicit); 5. Target audience; 6. Success metrics (after deployment); 7. Core user flows; 8. Functional requirements; 9. Pricing & limits (hybrid model); 10. AI & backend requirements; 11. Data model; 12. UX & tone requirements; 13. Risks & mitigations; 14. Implementation tracking; 15. Open decisions (tracked); 16. Revision history."
---

# Offload — Drag & Drop Ordering PRD

**Date:** 2026-01-22
**Status:** Proposed
**Owner:** Offload

**Related ADRs:**

- [adr-0002: Terminology Alignment](../adrs/adr-0002-terminology-alignment-for-capture-and-organization.md)
- [adr-0003: ADHD-Focused UX/UI Guardrails](../adrs/adr-0003-adhd-focused-ux-ui-guardrails.md)

---

## 1. Product overview

Enable drag-and-drop ordering for items in lists and plans, and allow plan items
to be nested by dragging onto another item, with indentation and collapsible
parent behavior.

---

## 2. Problem statement

Users cannot reorder items quickly or create hierarchy within plans, making it
harder to reflect priority and structure.

---

## 3. Product goals

- Support drag-and-drop ordering for lists and plans.
- Allow nesting within plans via drag-to-parent.
- Provide clear visual indentation and collapsible children.

---

## 4. Non-goals (explicit)

- Cross-collection drag-and-drop.
- Automatic prioritization or AI reordering.

---

## 5. Target audience

- Users managing projects or lists that require ordering.
- Users building multi-step plans with sub-tasks.

---

## 6. Success metrics (after deployment)

| Metric ID | Metric | Baseline | Target | Measurement |
| --- | --- | --- | --- | --- |
| M-220 | Drag reorder actions per active user | TBD | +25% | Analytics events |
| M-221 | Plan nesting adoption | TBD | 15% | Analytics events |

---

## 7. Core user flows

1. User drags a list item to a new position and releases to reorder.
2. User drags a plan item onto another to create a child relationship.
3. User collapses a parent item to hide child items.

---

## 8. Functional requirements

| Req ID | Requirement | Priority | User Story |
| --- | --- | --- | --- |
| FR-220 | Drag-and-drop reordering in list views. | Must | US-220 |
| FR-221 | Drag-and-drop reordering in plan views. | Must | US-221 |
| FR-222 | Drag item onto another to create a child in plans. | Must | US-222 |
| FR-223 | Children render indented under parent. | Must | US-223 |
| FR-224 | Parents can collapse/expand children. | Should | US-224 |

---

## 9. Pricing & limits (hybrid model)

Pricing and limits are deferred; see
[prd-0013: Pricing and Limits](prd-0013-pricing-limits.md).

---

## 10. AI & backend requirements

No new AI or backend requirements.

---

## 11. Data model

Hierarchy uses existing collection item ordering and parent relationships;
ordering changes must persist.

---

## 12. UX & tone requirements

- Drag interactions should be discoverable and forgiving.
- Nesting affordances must show clear feedback during drag.
- Collapsed states should be visually clear.

---

## 13. Risks & mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Drag gestures interfere with scroll | M | Tune gesture priority and feedback. |
| Accidental nesting leads to confusion | M | Offer clear indicators and easy undo. |

---

## 14. Implementation tracking

- Requires updates to list and plan item interactions and persistence.

---

## 15. Open decisions (tracked)

| Decision | Owner | Status | Notes |
| --- | --- | --- | --- |
| Collapsed state persistence | Product | Open | Determine if state is session-only. |

---

## 16. Revision history

| Version | Date | Notes |
| --- | --- | --- |
| N/A | 2026-01-22 | Initial proposal. |
