---
id: plans-readme
type: plan
status: active
owners:
  - Offload
applies_to:
  - Offload
last_updated: 2026-01-19
related:
  - plan-v1-roadmap
structure_notes:
  - "Section order: Purpose; Authority; What belongs here; What does not belong
    here; Canonical documents; Naming."
  - "Keep top-level sections: Purpose; Authority; What belongs here; What does
    not belong here; Canonical documents; Naming."
---

# Plans

## Purpose

Define sequencing, milestones, and execution strategy for approved scope.

## Authority

Below design. Plans describe WHEN and HOW work is executed; they cannot
introduce requirements, decisions, or architecture changes.

## What belongs here

- Milestones, work breakdowns, and sequencing.
- Dependencies, risks, and execution notes tied to approved scope.
- Progress tracking and rollout checklists.

## What does not belong here

- New requirements or scope (use prd/).
- Architecture or product decisions (use adr/).
- Technical designs or implementation details (use design/).
- Research notes or experiments (use research/).

## Canonical documents

### Active

- [Offload v1 Roadmap](./plan-v1-roadmap.md) - Single source of truth for v1

### Archived

All other plans have been archived to `_archived/`. See
[archived plans](./_archived/README.md) for historical context.

## Naming

- Use kebab-case with a concise feature or outcome, for example
  `plan-error-handling-improvements.md`.
- Move completed or superseded plans to `plans/_archived/` with
  `plan-archived-` prefix.
