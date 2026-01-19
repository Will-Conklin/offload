---
id: plans-readme
type: plan
status: active
owners:
  - offload
applies_to:
  - offload
last_updated: 2026-01-17
related:
  - plan-master-plan
  - plan-view-decomposition
  - plan-pagination-implementation
  - plan-repository-pattern-consistency
  - plan-tag-relationship-refactor
  - plan-error-handling-improvements
structure_notes:
  - "Section order: Purpose; Authority; What belongs here; What does not belong here; Canonical documents; Naming."
  - "Keep top-level sections: Purpose; Authority; What belongs here; What does not belong here; Canonical documents; Naming."
---


# Plans

## Purpose

Define sequencing, milestones, and execution strategy for approved scope.

## Authority

Below design. Plans describe WHEN and HOW work is executed; they cannot introduce requirements, decisions, or architecture changes.

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

- ⚠️ **[Master Plan Reconciliation (Jan 19, 2026)](./RECONCILIATION-2026-01-19.md)** - READ THIS FIRST
- [Offload Master Implementation Plan](./plan-master-plan.md) - ⚠️ Requires updates (see reconciliation)
- [View Decomposition Plan](./plan-view-decomposition.md)
- [Pagination Implementation Plan](./plan-pagination-implementation.md)
- [Repository Pattern Consistency Plan](./plan-repository-pattern-consistency.md)
- [Tag Relationship Refactor Plan](./plan-tag-relationship-refactor.md)
- [Error Handling Improvements Plan](./plan-error-handling-improvements.md)

### ⚠️ Important Note (Jan 19, 2026)

The master plan was created on Jan 9-10, but major changes occurred on Jan 13 that were not reflected in the plan. See [RECONCILIATION-2026-01-19.md](./RECONCILIATION-2026-01-19.md) for details on:
- UI direction change (flat design vs planned glassmorphism)
- Data model simplification (4 models instead of 13+)
- Repository pattern status (not complete as claimed)
- Error handling status (21 try? instances remain)
- Realistic timeline to v1 (5 weeks, not 8-10)

## Naming

- Use kebab-case with a concise feature or outcome, for example `plan-error-handling-improvements.md`.
- Move completed or superseded plans to `plans/_archived/` without renaming.
