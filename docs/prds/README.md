---
id: prds-readme
type: product-requirements
status: accepted
owners:
  - Will-Conklin
applies_to:
  - product
last_updated: 2026-01-25
related:
  - prd-0001-product-requirements
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Purpose; Authority; Lifecycle; What belongs here; What does not belong here; Canonical documents; Template; Naming."
  - "Keep top-level sections: Purpose; Authority; Lifecycle; What belongs here; What does not belong here; Canonical documents; Template; Naming."
---

# PRD

## Purpose

Define product requirements, scope, goals, and success metrics for Offload.

## Authority

Below reference and adrs. PRDs define WHAT the product must do; they cannot introduce architecture decisions or implementation details, and must align with reference and ADRs.

## Lifecycle

```text
proposed → accepted → implemented → archived
```

| Status         | Meaning                                           |
| -------------- | ------------------------------------------------- |
| `proposed`     | Initial idea, not yet fully scoped or reviewed    |
| `accepted`     | Approved for implementation                       |
| `implemented`  | Delivered and authoritative                       |
| `archived`     | Superseded or no longer applicable                |

## What belongs here

- Product goals, non-goals, and scope constraints.
- User flows, success metrics, and acceptance criteria.
- Pricing, limits, and roll-out requirements.

## What does not belong here

- Architecture or product decisions (use adrs/).
- Implementation details or technical designs (use design/).
- Execution timelines or task breakdowns (use plans/).
- Exploratory research or experiments (use research/).

## Canonical documents

- [Offload Product Requirements](./prd-0001-product-requirements.md)
- [Pricing and Limits PRD (Proposed)](./prd-0013-pricing-limits.md)

## Template

```markdown
---
id: prd-NNNN-{feature-name}
type: product-requirements
status: proposed
owners:
  - TBD  # Never assume; use actual contributor name when known
applies_to:
  - product
last_updated: YYYY-MM-DD
related:
  - adr-0001-{decision-title}
depends_on:
  - docs/adrs/adr-0001-{decision-title}.md
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: 1. Product overview; 2. Problem statement; 3. Product goals; 4. Non-goals (explicit); 5. Target audience; 6. Success metrics (after deployment); 7. Core user flows; 8. Functional requirements; 9. Pricing & limits (hybrid model); 10. AI & backend requirements; 11. Data model; 12. UX & tone requirements; 13. Risks & mitigations; 14. Implementation tracking; 15. Open decisions (tracked); 16. Revision history."
---

# {Product Name} — Product Requirements Document (PRD)

**Date:** YYYY-MM-DD
**Status:** Proposed
**Owner:** {name}

**Related ADRs:**

- [adr-0001-{decision-title}](link)
- [adr-0002-{decision-title}](link)

---

## 1. Product overview

{What we are building and why it matters}

---

## 2. Problem statement

{User pain and context}

---

## 3. Product goals

- {Goal 1}
- {Goal 2}

---

## 4. Non-goals (explicit)

- {Non-goal 1}
- {Non-goal 2}

---

## 5. Target audience

- {Primary audience}
- {Secondary audience}

---

## 6. Success metrics (after deployment)

| Metric ID | Metric   | Baseline  | Target | Measurement |
| --------- | -------- | --------- | ------ | ----------- |
| M-001     | {metric} | {current} | {goal} | {how}       |

---

## 7. Core user flows

1. {Flow 1}
2. {Flow 2}

---

## 8. Functional requirements

| Req ID | Requirement   | Priority        | User Story |
| ------ | ------------- | --------------- | ---------- |
| FR-001 | {requirement} | Must/Should/Could | US-XXX     |

---

## 9. Pricing & limits (hybrid model)

{Pricing tiers, usage limits, and constraints}

---

## 10. AI & backend requirements

{AI behavior, backend services, data handling}

---

## 11. Data model

{Key entities and relationships}

---

## 12. UX & tone requirements

{Voice, tone, and UX guardrails}

---

## 13. Risks & mitigations

| Risk   | Impact   | Mitigation   |
| ------ | -------- | ------------ |
| {risk} | {impact} | {mitigation} |

---

## 14. Implementation tracking

{Milestones, dependencies, or references}

---

## 15. Open decisions (tracked)

| Decision   | Owner  | Status | Notes   |
| ---------- | ------ | ------ | ------- |
| {decision} | {name} | Open   | {notes} |

---

## 16. Revision history

| Version | Date | Notes |
| --- | --- | --- |
| N/A | YYYY-MM-DD | Initial proposal |
```

## Naming

- Use `prd-NNNN-feature-name.md` format with the next sequential number.
- Keep filenames stable once published; use revision history inside the document.
