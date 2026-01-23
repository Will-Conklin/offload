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

The CI pipeline runs lane-specific checks based on path changes, with a docs-only
lane for documentation updates and a manual or scheduled full-run option.

## Schema

### Lanes

| Lane | Scope | Notes |
| --- | --- | --- |
| Docs | `docs/**` and root `*.md` | Runs markdownlint and doc checks. |
| iOS | `ios/**` | Runs iOS build and tests. |
| Backend | `backend/**` | Runs backend checks. |
| Scripts | `scripts/**` | Runs scripts checks. |

### Triggers

| Trigger | Purpose |
| --- | --- |
| `pull_request` | Path-aware checks for PRs. |
| `workflow_dispatch` (`full_run=true`) | Force full CI suite. |
| `schedule` | Nightly full CI suite. |

## Invariants

- CI runs on GitHub Actions.
- Path filters and lane ownership follow `reference-ci-path-filters`.
- Docs-only changes run the Docs lane and skip non-doc lanes.
- Full runs execute all lanes regardless of paths.

## Examples

- A PR changing only `docs/**` runs the Docs lane and skips other lanes.
- A PR touching `ios/**` runs the iOS lane without Backend or Scripts lanes.
