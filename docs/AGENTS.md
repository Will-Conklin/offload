---
id: docs-agents
type: reference
status: active
owners:
  - Will-Conklin
applies_to:
  - agents
last_updated: 2026-02-23
related: []
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
---

# Documentation Agent Guide

## Scope

The single source of pending work is `docs/plans/plan-implementation-backlog.md`. It is self-contained — all relevant context from PRDs, ADRs, designs, and research is embedded directly.

## Agent Scope

- `docs/plans/plan-implementation-backlog.md` — agents may read and update
- `docs/plans/_archived/` — read-only historical reference, do not modify
- All other directories (`adrs/`, `prds/`, `design/`, `reference/`, `research/`, `discovery/`, `reviews/`) — **off-limits to agents**. These are human reference only. Do not read, modify, or reference them.

## Rules

- Do not create new plan files — add work items to the backlog instead
- Do not enforce documentation workflow dependencies
- `docs/index.yaml` is for human navigation only — agents should not rely on it
