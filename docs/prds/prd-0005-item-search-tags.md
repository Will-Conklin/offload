---
id: prd-0005-item-search-tags
type: product-requirements
status: proposed
owners:
  - Offload
applies_to:
  - product
last_updated: 2026-01-22
related:
  - adr-0003-adhd-focused-ux-ui-guardrails
structure_notes:
  - "Section order: 1. Product overview; 2. Problem statement; 3. Product goals (V1); 4. Non-goals (explicit); 5. Target audience; 6. Success metrics (30-day post-launch); 7. Core user flows; 8. Functional requirements; 9. Pricing & limits (hybrid model); 10. AI & backend requirements; 11. Data model (V1); 12. UX & tone requirements; 13. Risks & mitigations; 14. Implementation tracking; 15. Open decisions (tracked); 16. Revision history."
---

# Offload — V1.1 Item Search by Text or Tag PRD

**Version:** 1.1
**Date:** 2026-01-22
**Status:** Proposed
**Owner:** Offload

**Related ADRs:**

- [adr-0003: ADHD-Focused UX/UI Guardrails](../adrs/adr-0003-adhd-focused-ux-ui-guardrails.md)

---

## 1. Product overview

Add a magnifying glass icon near settings that reveals a floating search bar.
Search should match item text and tags, and show matched tags as selectable
chips for tag-scoped searches.

---

## 2. Problem statement

Users cannot quickly find items by text or tags from the main views, leading to
slow navigation and missed context.

---

## 3. Product goals (V1)

- Provide search access near settings with a floating search bar.
- Support search by item text and by tag.
- Allow tag matches to become selectable chips for narrowing results.

---

## 4. Non-goals (explicit)

- Full-screen search redesign.
- Advanced filtering beyond text and tag scope.

---

## 5. Target audience

- Users with large item lists and frequent reuse.
- Users who rely on tags to organize information.

---

## 6. Success metrics (30-day post-launch)

| Metric ID | Metric | Baseline | Target | Measurement |
| --- | --- | --- | --- | --- |
| M-230 | Search usage rate | TBD | +25% | Analytics events |
| M-231 | Time-to-item (search) | TBD | -20% | Task timing study |

---

## 7. Core user flows

1. User taps the search icon and types a query.
2. User selects a matched tag chip to scope search to tags.
3. User clears the search to return to normal view.

---

## 8. Functional requirements

| Req ID | Requirement | Priority | User Story |
| --- | --- | --- | --- |
| FR-230 | Show a search icon next to settings. | Must | US-230 |
| FR-231 | Present a floating search bar below the icon. | Must | US-231 |
| FR-232 | Search matches item text and tags. | Must | US-232 |
| FR-233 | Matching tags appear as selectable chips. | Should | US-233 |
| FR-234 | Chip selection scopes results to tag-only search. | Should | US-234 |

---

## 9. Pricing & limits (hybrid model)

No pricing or limits changes.

---

## 10. AI & backend requirements

No new AI or backend requirements.

---

## 11. Data model (V1)

Search uses existing item text and tag relationships.

---

## 12. UX & tone requirements

- Search bar appears below the icon and spans about two-thirds of the view.
- Tag chips follow existing item tag styling for consistency.
- Search interactions should minimize cognitive load.

---

## 13. Risks & mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Search UI overlaps existing controls | M | Validate placement across screen sizes. |
| Large datasets slow search results | M | Use efficient queries and input throttling. |

---

## 14. Implementation tracking

- Requires search UI placement near settings and item/tag query support.

---

## 15. Open decisions (tracked)

| Decision | Owner | Status | Notes |
| --- | --- | --- | --- |
| Tag chip interaction details | Product | Open | Define selected vs suggested states. |

---

## 16. Revision history

| Version | Date | Notes |
| --- | --- | --- |
| 1.1 | 2026-01-22 | Initial proposal. |
