---
id: plans-readme
type: plan
status: accepted
owners:
  - Will-Conklin
applies_to:
  - plans
last_updated: 2026-01-25
related: []
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
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
proposed → accepted → in-progress → completed/archived
```

| Status         | Meaning                                      |
| -------------- | -------------------------------------------- |
| `proposed`     | Plan drafted, not yet approved               |
| `accepted`     | Approved and ready to start                  |
| `in-progress`  | Work underway                                |
| `completed`    | All work finished successfully               |
| `archived`     | Superseded, abandoned, or no longer relevant |

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

### In Progress

- [Plan: Testing & Polish](./plan-testing-polish.md)
- [Plan: Release Prep](./plan-release-prep.md)

### Accepted

- [Plan: Persistent Bottom Tab Bar](./plan-persistent-bottom-tab-bar.md)
- [Plan: Convert Plans and Lists](./plan-convert-plans-lists.md)
- [Plan: Drag and Drop Ordering](./plan-drag-drop-ordering.md)
- [Plan: Item Search by Text or Tag](./plan-item-search-tags.md)
- [Plan: Logging Implementation](./plan-logging-implementation.md)
- [Plan: Context-Aware CI Pipeline](./plan-context-aware-ci-pipeline.md)

### Proposed (Pending Confirmations)

- [Plan: Tag Relationship Refactor](./plan-tag-relationship-refactor.md)
- [Plan: View Decomposition](./plan-view-decomposition.md)
- [Plan: Visual Timeline](./plan-visual-timeline.md)
- [Plan: Celebration Animations](./plan-celebration-animations.md)
- [Plan: Advanced Accessibility Features](./plan-advanced-accessibility.md)
- [Plan: AI Organization Flows & Review Screen](./plan-ai-organization-flows.md)
- [Plan: AI Pricing & Limits](./plan-ai-pricing-limits.md)
- [Plan: Backend API + Privacy Constraints](./plan-backend-api-privacy.md)

### Archived

Archived plans have been moved to `_archived/`. See
[archived plans](./_archived/README.md) for historical context.
Notable archived plans include:

- [Offload Roadmap](./_archived/plan-roadmap.md)

## Template

```markdown
---
id: plan-{feature-name}
type: plan
status: proposed
owners:
  - TBD  # Never assume; use actual contributor name when known
applies_to:
  - {area}
last_updated: YYYY-MM-DD
related:
  - prd-0001-{feature-name}
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; User Verification; Progress."
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

## User Verification

- [ ] User verification complete.

## Progress

| Date       | Update              |
| ---------- | ------------------- |
| YYYY-MM-DD | {progress update}   |
```

## Naming

- Use kebab-case with a concise feature or outcome, for example
  `plan-error-handling-improvements.md`.
- Move completed or superseded plans to `plans/_archived/`.
- Keep original filenames when archiving to preserve links; avoid renaming.
