---
id: reference-ci-path-filters
type: reference
status: active
owners:
  - Offload
applies_to:
  - ci
last_updated: 2026-01-22
related:
  - adr-0007-context-aware-ci-workflow-strategy
  - prd-0006-context-aware-ci-pipeline
structure_notes:
  - "Section order: Definition; Schema; Invariants; Examples."
---

# CI Path Filters and Lane Triggers

## Definition

The context-aware CI pipeline uses path filters and explicit triggers to select
which lanes run for a change set.

## Schema

### Workflow Triggers

| Trigger | Description | Full Run | Owner |
| --- | --- | --- | --- |
| `pull_request` | Default validation for PRs. | No | CI maintainers |
| `workflow_dispatch` (`full_run=true`) | Manual full CI run. | Yes | CI maintainers |
| `schedule` | Nightly full CI run. | Yes | CI maintainers |

### Lane Path Filters

| Lane | Paths | Owner | Notes |
| --- | --- | --- | --- |
| Docs | `docs/**`, root `*.md` | Docs + CI maintainers | Runs markdownlint. |
| iOS | `ios/**` | iOS | Runs iOS build/tests. |
| Backend | `backend/**` | Backend | Runs backend checks. |
| Scripts | `scripts/**` | Automation | Runs scripts checks. |

## Invariants

- Docs-only changes are those limited to `docs/**` and root-level `*.md` files.
- Docs-only changes skip non-doc lanes.
- Full runs execute all lanes regardless of paths.

## Examples

- `docs/design/design-context-aware-ci-pipeline.md` → docs lane only.
- `README.md` → docs lane only.
- `ios/Offload/App/OffloadApp.swift` → iOS lane.
- `docs/` + `ios/` changes → docs + iOS lanes.
