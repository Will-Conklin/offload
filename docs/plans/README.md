---
id: plans-readme
type: plan
status: accepted
owners:
  - Will-Conklin
applies_to:
  - plans
last_updated: 2026-02-16
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

| Status        | Meaning                                             |
| ------------- | --------------------------------------------------- |
| `proposed`    | Plan drafted, not yet approved                      |
| `accepted`    | Approved and ready to start                         |
| `in-progress` | Work underway or merged code awaiting verification  |
| `completed`   | All work finished successfully                      |
| `archived`    | Superseded, abandoned, or no longer relevant        |

### Post-Merge User Verification Workflow

- Merge and close implementation PRs when implementation work is complete.
- If User Verification checklist items remain, open a follow-up GitHub issue labeled `uat`.
- Add the `uat` issue to the Offload project and link it to the plan and merged PR.
- Keep the plan status as `in-progress` until User Verification is complete.
- Move the plan to `completed` (or `archived`) only after User Verification is fully checked and the `uat` issue is closed.

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
- [Plan: Convert Plans and Lists](./plan-convert-plans-lists.md)
- [Plan: Drag and Drop Ordering](./plan-drag-drop-ordering.md)
- [Plan: Item Search by Text or Tag](./plan-item-search-tags.md)
- [Plan: UX & Accessibility Audit Fixes](./plan-ux-accessibility-audit-fixes.md)
- [Plan: View Decomposition](./plan-view-decomposition.md)
- [Plan: Fix Swipe-to-Delete in Organize View](./plan-fix-swipe-to-delete.md)
- [Plan: Resolve Gesture Conflict on Collection Cards](./plan-resolve-gesture-conflict.md)
- [Plan: Atomic Move to Collection](./plan-fix-atomic-move-to-collection.md)
- [Plan: Fix Orphaned Collection Links in CollectionItemRepository](./plan-fix-orphaned-collection-links.md)
- [Plan: Fix Voice Recording Service Off-Main-Actor Mutations](./plan-fix-voice-recording-threading.md)
- [Plan: Fix Collection Form Sheet Dismissing on Save Failure](./plan-fix-collection-form-dismissal.md)
- [Plan: Tag Relationship Refactor (Pending Confirmation)](./plan-tag-relationship-refactor.md)
- [Plan: Fix Structured Item Position Collisions](./plan-fix-structured-item-position-collisions.md)
- [Plan: Fix Tag Usage Semantics](./plan-fix-tag-usage-semantics.md)
- [Plan: Diagnose Idle Memory Pressure](./plan-diagnose-idle-memory-pressure.md)
- [Plan: Fix Collection Position Backfill](./plan-fix-collection-position-backfill.md)
- [Plan: Backend API + Privacy Constraints MVP (Breakdown-First)](./plan-backend-api-privacy.md)

### Proposed

- [Plan: Backend Session Security Hardening](./plan-backend-session-security-hardening.md)
- [Plan: Backend Reliability and Durability Hardening](./plan-backend-reliability-durability.md)
- [Plan: iOS Data and Performance Hardening](./plan-ios-data-performance-hardening.md)
- [Plan: Tab Shell Accessibility Hardening](./plan-tab-shell-accessibility-hardening.md)
- [Plan: Visual Timeline (Pending Confirmation)](./plan-visual-timeline.md)
- [Plan: Celebration Animations (Pending Confirmation)](./plan-celebration-animations.md)
- [Plan: Advanced Accessibility Features (Pending Confirmation)](./plan-advanced-accessibility.md)
- [Plan: AI Organization Flows & Review Screen (Pending Confirmation)](./plan-ai-organization-flows.md)
- [Plan: AI Pricing & Limits (Pending Confirmation)](./plan-ai-pricing-limits.md)

### Completed

- [Plan: Fix Tag Assignment Persistence](./plan-fix-tag-assignment.md)

### Archived

Archived plans have been moved to `_archived/`. See
[archived plans](./_archived/README.md) for historical context.
Notable archived plans include:

- [Offload Roadmap](./_archived/plan-roadmap.md)
- [Persistent Bottom Tab Bar](./_archived/plan-persistent-bottom-tab-bar.md)
- [Logging Implementation](./_archived/plan-logging-implementation.md)
- [Context-Aware CI Pipeline](./_archived/plan-context-aware-ci-pipeline.md)

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
