---
id: prds-readme
type: product-requirements
status: active
owners:
  - Offload
applies_to:
  - product
last_updated: 2026-01-17
related:
  - prd-0001-product-requirements
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
proposed → draft → review → active → deprecated
```

| Status       | Meaning                                           |
| ------------ | ------------------------------------------------- |
| `proposed`   | Initial idea, not yet fully scoped or reviewed    |
| `draft`      | Being written, not yet ready for review           |
| `review`     | Under stakeholder review                          |
| `active`     | Approved and authoritative                        |
| `deprecated` | Superseded or no longer applicable                |

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

- [Offload V1 PRD](./prd-0001-product-requirements.md)

## Template

```markdown
---
id: prd-NNNN-{feature-name}
type: product-requirements
status: proposed
owners:
  - {name}
applies_to:
  - product
last_updated: YYYY-MM-DD
related:
  - adr-0001-{decision-title}
structure_notes:
  - "Section order: 1. Product overview; 2. Problem statement; 3. Product goals (V1); 4. Non-goals (explicit); 5. Target audience; 6. Success metrics (30-day post-launch); 7. Core user flows; 8. Functional requirements; 9. Pricing & limits (hybrid model); 10. AI & backend requirements; 11. Data model (V1); 12. UX & tone requirements; 13. Risks & mitigations; 14. Implementation tracking; 15. Open decisions (tracked); 16. Revision history."
---

# {Product Name} — V{major} Product Requirements Document (PRD)

**Version:** {major}.{minor}
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

## 3. Product goals (V1)

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

## 6. Success metrics (30-day post-launch)

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

## 11. Data model (V1)

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

| Version         | Date       | Notes         |
| --------------- | ---------- | ------------- |
| {major}.{minor} | YYYY-MM-DD | Initial proposal |
```

## Naming

- Use `prd-NNNN-feature-name.md` format with the next sequential number.
- Keep filenames stable once published; use revision history inside the document.
