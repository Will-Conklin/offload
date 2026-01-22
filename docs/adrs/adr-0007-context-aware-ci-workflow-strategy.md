---
id: adr-0007-context-aware-ci-workflow-strategy
type: architecture-decision
status: accepted
owners:
  - product
  - ios
applies_to:
  - ci
  - workflows
  - automation
last_updated: 2026-01-21
related:
  - prd-0006-context-aware-ci-pipeline
  - adr-0006-ci-provider-selection
structure_notes:
  - "Section order: Context; Decision; Consequences; Alternatives Considered; Implementation Notes; References; Revision History."
decision-date: 2026-01-21
decision-makers:
  - product
  - ios
---

# adr-0007: Context-Aware CI Workflow Strategy

**Status:** Accepted  
**Decision Date:** 2026-01-21  
**Deciders:** Product, iOS  
**Tags:** ci, workflows, automation

## Context

PRD-0006 defines a context-aware CI pipeline with docs-only and path-based
lanes. We need to formalize how changes are classified and which workflows run
for each change type.

## Decision

- Use path-based workflow gating to select CI lanes.
- Define docs-only changes as updates limited to `docs/**` and root-level
  `*.md` files (for example `README.md`).
- Provide a docs-only lane that runs markdownlint and doc-specific checks.
- Run iOS checks for changes under `ios/**`.
- Run backend checks for changes under `backend/**`.
- Run automation checks for changes under `scripts/**`.
- Mixed changes run all relevant lanes.
- Provide a manual override to trigger the full CI suite.
- Schedule a nightly full run to catch path filter misses.

## Consequences

- CI runtime improves for narrow-scope changes while maintaining coverage.
- Path classification becomes an explicit contract that must be maintained.
- Manual and scheduled full runs mitigate the risk of missed checks.

## Alternatives Considered

- Always run the full CI suite. Rejected due to slow feedback.
- Single workflow with internal conditionals only. Rejected to keep jobs and
  ownership clearer per lane.
- Manual-only full runs without a schedule. Rejected due to increased risk of
  missed validation.

## Implementation Notes

- Report the chosen lane(s) in CI summaries for clarity.
- Keep the path filters and lane definitions documented for maintainers.

## References

- [prd-0006: Context-Aware CI Pipeline](../prds/prd-0006-context-aware-ci-pipeline.md)
- [adr-0006: CI Provider Selection](./adr-0006-ci-provider-selection.md)

## Revision History

| Version | Date       | Notes            |
| ------- | ---------- | ---------------- |
| 1.0     | 2026-01-21 | Initial proposal |
| 1.1     | 2026-01-21 | Accepted         |
