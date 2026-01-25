---
id: design-context-aware-ci-pipeline
type: design
status: accepted
owners:
  - Offload
applies_to:
  - ci
last_updated: 2026-01-22
related:
  - prd-0006-context-aware-ci-pipeline
  - adr-0006-ci-provider-selection
  - adr-0007-context-aware-ci-workflow-strategy
depends_on:
  - docs/prds/prd-0006-context-aware-ci-pipeline.md
  - docs/adrs/adr-0006-ci-provider-selection.md
  - docs/adrs/adr-0007-context-aware-ci-workflow-strategy.md
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Overview; Architecture; Data Flow; UI Behavior; Testing; Constraints."
---

# Design: Context-Aware CI Pipeline

## Overview

This design implements PRD-0006 using GitHub Actions (ADR-0006) and the
path-based workflow strategy in ADR-0007. The goal is to run only the checks
required for a given pull request while preserving a manual override and a
scheduled full CI run.

## Architecture

- **CI provider:** GitHub Actions workflows in `.github/workflows/`.
- **Workflow entry points:**
  - `pull_request` for normal PR validation.
  - `workflow_dispatch` with a `full_run` boolean to force the full suite.
  - `schedule` (nightly) for the full CI suite.
- **Change detection job:** A lightweight job computes which paths changed and
  outputs lane flags (`docs_changed`, `docs_only`, `ios`, `backend`, `scripts`,
  `full_run`).
- **Lane jobs:** Docs, iOS, backend, and scripts jobs run conditionally based on
  the change detection outputs or when `full_run` is true.
  - Docs lane runs markdownlint and any doc checks.
  - Backend/scripts lanes run linters and a Snyk scan (or equivalent).
- **Concurrency:** Use workflow-level concurrency to avoid redundant runs on the
  same branch/ref.

Example trigger skeleton (per GitHub Actions syntax):

```yaml
on:
  pull_request:
  workflow_dispatch:
    inputs:
      full_run:
        description: 'Run the full CI suite'
        required: false
        default: false
        type: boolean
  schedule:
    - cron: '30 4 * * *'
```

## Data Flow

1. Workflow triggers on `pull_request`, `workflow_dispatch`, or `schedule`.
2. `detect-changes` checks out the repo and runs:
   - `git diff --name-only ${{ github.event.pull_request.base.sha }}...${{ github.sha }}`
     for PRs.
   - A full run flag for `schedule` or `workflow_dispatch` with `full_run=true`.
3. The job classifies files into lanes:
   - Docs changed: any updates under `docs/**` or root-level `*.md`.
   - Docs-only: docs changes and nothing else.
   - iOS: `ios/**`.
   - Backend: `backend/**`.
   - Scripts: `scripts/**`.
4. Lane jobs run with `if:` guards based on those outputs.
   - Docs lane runs when docs changed, even on mixed PRs.
   - Non-docs lanes are skipped when docs-only is true.
5. Each job reports its lane in the job name and summary for clarity.

## UI Behavior

No app UI changes. CI check names and summaries clearly state the lane(s) that
ran and why (docs-only vs iOS vs backend vs scripts vs full run).

## Testing

- **Docs-only PR:** Modify `docs/**` and verify only the docs lane runs.
- **Root-level docs PR:** Modify `README.md` and verify only the docs lane runs.
- **iOS-only PR:** Modify `ios/**` and verify iOS lane runs without docs lane.
- **Mixed PR:** Modify both `docs/**` and `ios/**` and verify docs + iOS lanes run.
- **Manual full run:** Trigger `workflow_dispatch` with `full_run=true` and
  verify all lanes run.
- **Scheduled run:** Verify the nightly schedule runs the full suite on default
  branch.

## Constraints

- Must use GitHub Actions (ADR-0006).
- Must implement path-based lane gating, docs-only definition, manual override,
  and nightly full run (ADR-0007).
- Do not introduce new testing frameworks beyond existing tooling (PRD-0006).
- Keep local developer workflow lightweight; CI is the primary enforcement path.
