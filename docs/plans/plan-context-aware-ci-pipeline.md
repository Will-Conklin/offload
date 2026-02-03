---
id: plan-context-aware-ci-pipeline
type: plan
status: complete
owners:
  - Will-Conklin
applies_to:
  - ci
last_updated: 2026-02-03
related:
  - prd-0006-context-aware-ci-pipeline
  - adr-0006-ci-provider-selection
  - adr-0007-context-aware-ci-workflow-strategy
  - design-context-aware-ci-pipeline
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Overview; Goals; Phases; Dependencies; Risks; User Verification; Progress."
---

# Plan: Context-Aware CI Pipeline

## Overview

Implement GitHub Actions workflows with path-based lane gating, a manual full
run override, and a scheduled full CI run per PRD-0006.

## Goals

- Build the change-detection job and lane gating described in ADR-0007.
- Ensure docs-only changes run only docs checks.
- Preserve manual override and nightly full run.

## Phases

### Phase 1: Workflow Skeleton

**Status:** Complete

- [x] Add workflow triggers for `pull_request`, `workflow_dispatch` with
      `full_run`, and `schedule`.
- [x] Configure concurrency to avoid redundant runs on the same ref.
- [x] Establish shared environment/outputs for lane flags.

### Phase 2: Change Detection

**Status:** Complete

- [x] Implement `detect-changes` job and lane outputs (`docs_changed`,
      `docs_only`, `ios`, `backend`, `scripts`, `full_run`).
- [x] Align path rules with the design doc (docs/**, root *.md, ios/**,
      backend/**, scripts/**).

### Phase 3: Lane Jobs

**Status:** Complete

- [x] Add docs lane (markdownlint + doc checks).
- [x] Add iOS, backend, scripts lanes with existing tooling.
- [x] Gate lanes with `if:` using change outputs and full_run.

### Phase 4: Validation

**Status:** Complete

- [x] Verify docs-only, iOS-only, mixed, manual full run, and scheduled run
      scenarios.

## Dependencies

- Design: `design-context-aware-ci-pipeline`.
- ADRs: `adr-0006` provider selection and `adr-0007` workflow strategy.
- PRD: `prd-0006-context-aware-ci-pipeline`.
- Existing linting and security tooling (markdownlint, backend, scripts).

## Risks

| Risk                                      | Impact | Mitigation                                          |
| ----------------------------------------- | ------ | --------------------------------------------------- |
| Change detection misclassifies paths      | H      | Keep path rules minimal and covered by QA scenarios.|
| Docs-only PRs still trigger non-doc lanes | M      | Ensure `docs_only` guard is applied to other lanes. |
| Full runs missed on schedule              | M      | Validate cron schedule and monitor runs.            |
| Required checks mismatch lane names       | M      | Coordinate required checks with workflow job names. |

## User Verification

- [x] User verification complete.

## Progress

| Date       | Update                                                  |
| ---------- | ------------------------------------------------------- |
| 2026-01-22 | Draft plan created.                                     |
| 2026-01-22 | Implemented workflow gating, lanes, and docs reference. |
| 2026-02-03 | Validated through multiple successful PR runs. Plan complete. |
