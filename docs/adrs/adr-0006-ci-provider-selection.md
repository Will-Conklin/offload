---
id: adr-0006-ci-provider-selection
type: architecture-decision
status: accepted
owners:
  - product
  - ios
applies_to:
  - ci
  - infrastructure
  - automation
last_updated: 2026-01-21
related:
  - prd-0006-context-aware-ci-pipeline
structure_notes:
  - "Section order: Context; Decision; Consequences; Alternatives Considered; Implementation Notes; References; Revision History."
decision-date: 2026-01-21
decision-makers:
  - product
  - ios
---

# adr-0006: CI Provider Selection

**Status:** Accepted  
**Decision Date:** 2026-01-21  
**Deciders:** Product, iOS  
**Tags:** ci, infrastructure

## Context

PRD-0006 requires a context-aware CI pipeline with path-based lanes and a
docs-only workflow. We need a CI provider that integrates tightly with the
repository and supports path filters, reusable workflows, and scheduled runs.

## Decision

Use GitHub Actions as the CI provider for Offload. This decision covers the
initial rollout of context-aware workflows and establishes GitHub Actions as the
default CI platform unless superseded.

## Consequences

- Workflow definitions will live in `.github/workflows/`.
- CI permissions and maintenance will be managed through GitHub.
- The team can leverage reusable workflows, concurrency controls, and scheduled
  runs without additional infrastructure.

## Alternatives Considered

- CircleCI. Rejected to avoid additional provider setup and billing overhead.
- Buildkite. Rejected due to infrastructure management requirements.
- Keep the current CI state and optimize later. Rejected due to immediate
  productivity impact.

## Implementation Notes

- Use reusable workflows and path-based filters for context-aware lanes.
- Provide a manual override to run the full CI suite.
- Add a scheduled full run to mitigate path filter gaps.

## References

- [prd-0006: Context-Aware CI Pipeline](../prds/prd-0006-context-aware-ci-pipeline.md)

## Revision History

| Version | Date       | Notes            |
| ------- | ---------- | ---------------- |
| 1.0     | 2026-01-21 | Initial proposal |
| 1.1     | 2026-01-21 | Accepted         |
