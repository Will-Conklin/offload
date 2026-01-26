---
id: discovery-readme
type: discovery
status: active
owners:
  - Will-Conklin
applies_to:
  - discovery
last_updated: 2026-01-25
related: []
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Purpose; Authority; Lifecycle; What belongs here; What does not belong here; Canonical documents; Naming."
  - "Keep top-level sections: Purpose; Authority; Lifecycle; What belongs here; What does not belong here; Canonical documents; Naming."
---

# Discovery

## Purpose

Capture early feature exploration and context gathering before formal requirements.

## Authority

Non-authoritative. Discovery docs inform PRDs but must not define requirements or decisions.

## Lifecycle

```text
active -> completed -> abandoned
```

| Status      | Meaning                                       |
| ----------- | --------------------------------------------- |
| `active`    | Discovery work in progress                    |
| `completed` | Discovery finished and summarized in a PRD    |
| `abandoned` | No longer pursued or relevant                 |

## What belongs here

- Initial feature exploration
- Problem space investigation
- User need discovery
- Competitive analysis
- Feasibility assessment
- Open questions and uncertainties

## What does not belong here

- Product requirements or scope (use prd/).
- Architecture or product decisions (use adr/).
- Implementation plans or schedules (use plans/).
- Technical design (use design/).

## Canonical documents

- None yet.

## Naming

- Use `discovery-{topic}.md` for topic-based exploration.
- Use date prefixes for time-bound work.
