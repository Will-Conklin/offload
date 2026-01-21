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
  - "Section order: Purpose; Authority; Lifecycle; What belongs here; What does
    not belong here; Canonical documents; Template; Naming."
  - "Keep top-level sections: Purpose; Authority; Lifecycle; What belongs here;
    What does not belong here; Canonical documents; Template; Naming."
---

# Plans

## Purpose

Define sequencing, milestones, and execution strategy for approved scope.

## Authority

Below design. Plans describe WHEN and HOW work is executed; they cannot
introduce requirements, decisions, or architecture changes.

## Lifecycle

```text
draft → active → completed | archived
```

| Status      | Meaning                                         |
| ----------- | ----------------------------------------------- |
| `draft`     | Plan being developed, not yet approved          |
| `active`    | Approved and in execution                       |
| `completed` | All work finished successfully                  |
| `archived`  | Superseded, abandoned, or no longer relevant    |

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

## Template

```markdown
---
id: plan-{feature-name}
type: plan
status: active
owners:
  - {name}
applies_to:
  - {area}
last_updated: YYYY-MM-DD
related:
  - prd-0001-{feature-name}
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; Progress."
---

# Plan: {Feature Name}

## Overview

{Brief description of what this plan covers and its relationship to approved
scope}

## Goals

- {Goal 1}
- {Goal 2}

## Phases

### Phase 1: {Phase Name}

**Status:** Not Started | In Progress | Completed

- [ ] Task 1
- [ ] Task 2

### Phase 2: {Phase Name}

**Status:** Not Started | In Progress | Completed

- [ ] Task 1
- [ ] Task 2

## Dependencies

- {Dependency 1}
- {Dependency 2}

## Risks

| Risk   | Impact | Mitigation   |
| ------ | ------ | ------------ |
| {risk} | {H/M/L} | {mitigation} |

## Progress

| Date       | Update              |
| ---------- | ------------------- |
| YYYY-MM-DD | {progress update}   |
```

## Naming

- Use kebab-case with a concise feature or outcome, for example
  `plan-error-handling-improvements.md`.
- Move completed or superseded plans to `plans/_archived/` with
  `plan-archived-` prefix.
