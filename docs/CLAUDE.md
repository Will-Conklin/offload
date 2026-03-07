# Documentation Agent Scope

This file governs how Claude Code and other agents interact with the `docs/` directory. See the root `CLAUDE.md` for repository-wide rules.

## What Agents May Modify

- `docs/plans/backlog.md` — add, update, or remove backlog items
- `docs/plans/*.md` (plan docs) — update task status, add findings, mark tasks complete
- `docs/plans/_archived/` — read-only historical reference; do not modify

## What Agents Must Not Modify

- `docs/product.md` — human-maintained; reflects product decisions
- `docs/architecture.md` — human-maintained; reflects architectural decisions
- `docs/design.md` — human-maintained; reflects UX and testing standards
- `docs/CLAUDE.md` — this file; human-maintained

## Backlog Rules

- The backlog (`docs/plans/backlog.md`) lists known bugs, features, and enhancements that do not yet have a plan doc
- When a plan doc is created in `docs/plans/`, the corresponding backlog item is removed
- Do not add implementation detail to the backlog — keep it as a list of items to plan
- Do not create plan docs without human instruction

## Plan Doc Rules

- Each plan doc covers one unified body of work
- Plans are broken into phases or tasks sized for agent handoff
- Agents may update task status and add completion notes within an assigned plan
- Do not modify plan scope or add new phases without human instruction

## What the Backlog Is Not

The backlog is not a task tracker for in-progress work. Active work is tracked in its plan doc. The backlog is only for items that have not yet been planned.
