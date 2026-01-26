---
id: plans-agents
type: reference
status: active
owners:
  - Will-Conklin
applies_to:
  - agents
  - plans
last_updated: 2026-01-25
related:
  - docs-agents
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Scope; Purpose; Contains; When to create; Lifecycle; Format expectations; Boundaries."
---
# Plans Agent Guide

This file provides agent-only instructions for documentation in `docs/plans/`.
README files are informational for users.

## Scope

- Applies to `docs/plans/**`
- Defers to `docs/AGENTS.md` for global documentation rules

## Purpose

Define execution sequencing, milestones, and task breakdown (WHEN).

## Contains

- Task breakdown and dependencies
- Implementation phases and milestones
- Work sequencing and order
- Effort estimates (when needed)
- Risk mitigation strategies
- Testing and validation approach

## When to create

- After PRDs, ADRs, and design docs are accepted
- Before implementation begins
- When execution strategy needs coordination
- For tracking progress on complex features

## Lifecycle

- Created after design docs, before implementation
- Status: proposed -> accepted -> in-progress -> completed/archived
- Updated as implementation progresses
- Plans can only move to completed/archived when every item in the User Verification section is checked
- Active plans tracked in `docs/plans/`
- Completed plans moved to `docs/plans/_archived/`

## Format expectations

- Ordered task list with dependencies
- Clear phases and milestones
- Links to GitHub issues for tracking
- References to design docs and PRDs
- A User Verification section with a checklist; agents must not update or check items in this section

## Boundaries

- Does not introduce new requirements (see PRDs)
- Does not make architectural decisions (see ADRs)
- Does not define technical approach (see design docs)
- Must have prerequisite docs complete before acceptance
- Agents must not modify the User Verification section in plans
