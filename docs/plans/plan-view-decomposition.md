---
id: plan-view-decomposition
type: plan
status: uat
owners:
  - Will-Conklin
applies_to:
  - ios
last_updated: 2026-02-18
related:
  - plan-roadmap
depends_on: []
supersedes: []
accepted_by: @Will-Conklin
accepted_at: 2026-01-19
related_issues:
  - https://github.com/Will-Conklin/offload/issues/117
  - https://github.com/Will-Conklin/Offload/issues/217
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: View Decomposition

## Overview

Decomposed oversized SwiftUI view files into focused, single-responsibility
modules. Completed via PR #137 (commit d9515d1), merged to main on 2026-02-09.
GitHub issue #117 and Linear PER-21 are both marked Done.

## Goals

- Reduce risk by breaking large views into focused components.
- Improve readability and maintainability before release.

## Phases

### Phase 1: Scope Confirmation

**Status:** Complete

- [x] Confirm scope approval in PRD/ADR updates.
- [x] Prioritize views based on size and complexity.

### Phase 2: Decomposition Plan

**Status:** Complete

- [x] Identify subviews and shared components.
- [x] Document sequencing and ownership boundaries.

### Phase 3: Refactor & Verification

**Status:** Complete

- [x] Implement view splits.
- [x] Verify navigation, bindings, and state flows.

## Dependencies

- Design system guidance for shared components (available in `DesignSystem/`).

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
| 2026-02-09 | All phases completed. PR #137 (d9515d1) merged to main. Issue #117 and Linear PER-21 closed as Done. Awaiting user verification. |
