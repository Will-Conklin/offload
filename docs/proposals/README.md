---
id: proposals-readme
type: reference
status: active
owners:
  - Offload
applies_to:
  - proposals
last_updated: 2026-01-19
related:
  - prds-readme
  - research-readme
structure_notes:
  - "Section order: Purpose; Authority; Lifecycle; What belongs here; What does
    not belong here; Template; Naming."
---

# Proposals

## Purpose

Capture structured ideas for features or improvements that are not yet ready for
a full PRD. Proposals bridge the gap between exploratory research and formal
product requirements.

## Authority

Below research, above nothing. Proposals are **non-authoritative** and represent
ideas under consideration. They do not define scope, requirements, or
commitments until promoted to a PRD.

## Lifecycle

```text
draft → under-review → accepted (→ PRD) | rejected | deferred
```

| Status         | Meaning                                      |
| -------------- | -------------------------------------------- |
| `draft`        | Initial idea, not yet reviewed               |
| `under-review` | Being evaluated for feasibility/fit          |
| `accepted`     | Approved to become a PRD                     |
| `rejected`     | Not proceeding (document kept for reference) |
| `deferred`     | Good idea, but not now                       |

## What belongs here

- Problem statements with proposed solutions
- Feature ideas with rough scope
- Enhancement suggestions
- Ideas extracted from research that warrant further exploration

## What does not belong here

- Finalized requirements (use `prds/`)
- Technical decisions (use `adrs/`)
- Implementation details (use `design/`)
- Execution plans (use `plans/`)
- Raw exploration without structure (use `research/`)

## Template

```markdown
---
id: proposal-<feature-name>
type: proposal
status: draft
owners:
  - <owner>
applies_to:
  - <area>
last_updated: YYYY-MM-DD
related: []
structure_notes:
  - "Keep proposals focused on problem and high-level solution"
---

# Proposal: <Feature Name>

## Problem

What problem does this solve? Who experiences it?

## Proposed Solution

High-level description of the approach.

## Open Questions

- Question 1?
- Question 2?

## Rough Effort

Small / Medium / Large / Unknown

## Next Steps

What needs to happen to move this forward?
```

## Naming

- Use kebab-case: `proposal-<feature-name>.md`
- Keep names descriptive but concise
- When promoted to PRD, archive the proposal to `proposals/_archived/`
