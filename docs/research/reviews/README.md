---
id: research-reviews-readme
type: research
status: active
owners:
  - Will-Conklin
applies_to:
  - reviews
last_updated: 2026-01-25
related:
  - research-2026-01-04-main-branch-review
  - research-2026-02-14-docs-plan-coverage-review
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Purpose; Authority; What belongs here; What does not belong here; Canonical documents; Naming."
  - "Keep top-level sections: Purpose; Authority; What belongs here; What does not belong here; Canonical documents; Naming."
---


# Reviews

## Purpose

Store review reports and assessment snapshots.

## Authority

Research-level authority. Reviews are informational and must not define requirements, decisions, or plans.

## What belongs here

- Code or documentation review reports.
- Findings summaries and recommendations.

## What does not belong here

- Architecture decisions or requirements (use adr/ or prd/).
- Implementation plans or schedules (use plans/).

## Canonical documents

- [Code Review: Main Branch - Comprehensive Analysis](./research-2026-01-04-main-branch-review.md)
- [Docs → Plan Coverage Review (2026-02-14)](./research-2026-02-14-docs-plan-coverage-review.md)

## Naming

- Use `research-YYYY-MM-DD-<scope>-review.md` for consistency.
- Keep scope concise and stable.
