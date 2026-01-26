---
id: plan-view-decomposition
type: plan
status: proposed
owners:
  - Will-Conklin
applies_to:
  - pending-confirmation
last_updated: 2026-01-25
related:
  - plan-roadmap
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: View Decomposition (Pending Confirmation)

## Overview

Execution plan for decomposing large SwiftUI views listed as optional proposed
scope in the roadmap. Work should begin only after scope is confirmed via
PRD/ADR updates.

## Goals

- Reduce risk by breaking large views into focused components.
- Improve readability and maintainability before release.

## Phases

### Phase 1: Scope Confirmation

**Status:** Not Started

- [ ] Confirm scope approval in PRD/ADR updates.
- [ ] Prioritize views based on size and complexity.

### Phase 2: Decomposition Plan

**Status:** Not Started

- [ ] Identify subviews and shared components.
- [ ] Document sequencing and ownership boundaries.

### Phase 3: Refactor & Verification

**Status:** Not Started

- [ ] Implement view splits.
- [ ] Verify navigation, bindings, and state flows.

## Dependencies

- Scope confirmation for proposed work.
- Updated design system guidance for shared components.

## Risks

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Refactor introduces regressions | M | Incremental refactors with focused QA. |
| Schedule impact | M | Prioritize only the largest views if time is limited. |

## User Verification

- [ ] User verification complete.

## Progress

| Date | Update |
| --- | --- |
| 2026-01-20 | Plan created from roadmap split. |
