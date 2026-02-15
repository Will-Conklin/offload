---
id: adrs-readme
type: architecture-decision
status: accepted
owners:
  - Will-Conklin
applies_to:
  - architecture
last_updated: 2026-02-15
related:
  - adr-0001-technology-stack-and-architecture
  - adr-0002-terminology-alignment-for-capture-and-organization
  - adr-0003-adhd-focused-ux-ui-guardrails
  - adr-0004-tab-bar-navigation-shell-and-offload-cta
  - adr-0005-collection-ordering-and-hierarchy-persistence
  - adr-0006-ci-provider-selection
  - adr-0007-context-aware-ci-workflow-strategy
  - adr-0008-backend-api-privacy-mvp
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Purpose; Authority; Lifecycle; What belongs here; What does not belong here; Canonical documents; Template; Naming."
  - "Keep top-level sections: Purpose; Authority; Lifecycle; What belongs here; What does not belong here; Canonical documents; Template; Naming."
---


# ADR

## Purpose

Record architecture and product decisions, including rationale and consequences.

## Authority

Second only to reference. ADRs define decisions and constraints; they must align with reference and cannot define requirements, scope, or implementation plans.

## Lifecycle

```text
proposed → accepted → superseded | deprecated
```

| Status       | Meaning                                      |
| ------------ | -------------------------------------------- |
| `proposed`   | Decision under consideration                 |
| `accepted`   | Decision approved and in effect              |
| `superseded` | Replaced by a newer ADR (link to successor)  |
| `deprecated` | No longer applicable                         |

## What belongs here

- Decisions with context, decision statement, and consequences.
- Alternatives considered and trade-offs.
- Status updates (Accepted, Superseded, Deprecated) with links.

## What does not belong here

- Product requirements or scope (use prd/).
- Implementation details or technical design (use design/).
- Execution plans, milestones, or schedules (use plans/).
- Exploratory research or raw notes (use research/).

## Canonical documents

- [adr-0001: Technology Stack and Architecture](./adr-0001-technology-stack-and-architecture.md)
- [adr-0002: Terminology Alignment for Capture and Organization](./adr-0002-terminology-alignment-for-capture-and-organization.md)
- [adr-0003: ADHD-Focused UX/UI Guardrails](./adr-0003-adhd-focused-ux-ui-guardrails.md)
- [adr-0004: Tab Bar Navigation Shell and Offload CTA](./adr-0004-tab-bar-navigation-shell-and-offload-cta.md)
- [adr-0005: Collection Ordering and Hierarchy Persistence](./adr-0005-collection-ordering-and-hierarchy-persistence.md)
- [adr-0006: CI Provider Selection](./adr-0006-ci-provider-selection.md)
- [adr-0007: Context-Aware CI Workflow Strategy](./adr-0007-context-aware-ci-workflow-strategy.md)
- [adr-0008: Backend API + Privacy Constraints MVP](./adr-0008-backend-api-privacy-mvp.md)

## Template

```markdown
---
id: adr-NNNN-{decision-title}
type: architecture-decision
status: proposed
owners:
  - TBD  # Never assume; use actual contributor name when known
applies_to:
  - architecture
last_updated: YYYY-MM-DD
related:
  - prd-0001-{feature-name}
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Context; Decision; Consequences; Alternatives Considered; Implementation Notes; References; Revision History."
decision-date: YYYY-MM-DD
decision-makers: [names]
---

# adr-NNNN: {Decision Title}

**Status:** Proposed
**Decision Date:** YYYY-MM-DD
**Deciders:** {names}
**Tags:** architecture

## Context

{What motivates this decision? What problem are we solving?}

## Decision

{What is the decision and why?}

## Consequences

- Good: {positive outcome}
- Bad: {tradeoff accepted}

## Alternatives Considered

- {Option 1}
- {Option 2}
- {Option 3}

## Implementation Notes

{Key implementation notes, constraints, or follow-ups}

## References

- {link to related docs, PRDs, or research}

## Revision History

| Version | Date       | Notes            |
| ------- | ---------- | ---------------- |
| 1.0     | YYYY-MM-DD | Initial decision |
```

## Naming

- Use `adr-NNNN-feature-name.md` format with the next sequential number.
- Keep titles in the file aligned with the ADR table of contents.
