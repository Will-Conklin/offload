---
id: reference-context-aware-ci-pipeline
type: reference
status: active
owners:
  - Offload
applies_to:
  - ci
last_updated: 2026-01-22
related:
  - prd-0006-context-aware-ci-pipeline
  - design-context-aware-ci-pipeline
  - plan-context-aware-ci-pipeline
  - adr-0006-ci-provider-selection
  - adr-0007-context-aware-ci-workflow-strategy
  - reference-ci-path-filters
structure_notes:
  - "Section order: Definition; Schema; Invariants; Examples."
---

# Context-Aware CI Pipeline

## Definition

A CI workflow that runs only the lanes required by a pull request based on
path-based change detection, with a manual full-run override and scheduled full
runs. This reference codifies the contracts described in the
[Context-Aware CI Pipeline PRD](../../prds/prd-0006-context-aware-ci-pipeline.md),
[design doc](../../design/design-context-aware-ci-pipeline.md), and
[implementation plan](../../plans/plan-context-aware-ci-pipeline.md).

## Schema

### Workflow Triggers

| Trigger | Purpose | Full Run |
| --- | --- | --- |
| `pull_request` | Default PR validation | No |
| `workflow_dispatch` (`full_run=true`) | Manual override | Yes |
| `schedule` | Nightly validation | Yes |

### Lane Outputs

| Output | Meaning | Source |
| --- | --- | --- |
| `docs_changed` | Docs files changed | Change detection job |
| `docs_only` | Only docs files changed | Change detection job |
| `ios` | iOS files changed | Change detection job |
| `backend` | Backend files changed | Change detection job |
| `scripts` | Scripts files changed | Change detection job |
| `full_run` | Full run requested | Manual or scheduled trigger |

### Lane Definitions

Lane path filters and ownership are defined in
[CI Path Filters and Lane Triggers](./reference-ci-path-filters.md).

## Invariants

- Docs lane runs for any change under `docs/**` or root-level `*.md` files.
- Docs-only changes skip non-doc lanes.
- Manual full runs and scheduled runs execute all lanes regardless of paths.
- The pipeline uses GitHub Actions per
  [ADR-0006](../../adrs/adr-0006-ci-provider-selection.md).
- Lane gating follows the strategy in
  [ADR-0007](../../adrs/adr-0007-context-aware-ci-workflow-strategy.md).

## Examples

- A PR that changes only `docs/prds/prd-0006-context-aware-ci-pipeline.md`
  runs the docs lane only.
- A PR that changes `ios/Offload/App/OffloadApp.swift` runs the iOS lane.
- A manual `workflow_dispatch` with `full_run=true` runs all lanes.
