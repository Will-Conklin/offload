---
id: plans-agents
type: reference
status: active
owners:
  - Will-Conklin
applies_to:
  - agents
  - plans
last_updated: 2026-02-18
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
- Status: proposed -> accepted -> in-progress -> uat -> completed/archived
- Updated as implementation progresses
- If a user explicitly instructs implementation to begin, treat that instruction
  as plan acceptance unless the plan is marked pending confirmation.
- On implicit acceptance, set `accepted_by` to the GitHub handle format
  (`@username`) for the active GitHub account and set `accepted_at` to the date
  implementation first began.
- Prefer the authenticated `gh` account login as the source for
  `accepted_by` and use `git config user.name` only as a fallback if GitHub
  identity is unavailable.
- Plans can only move to completed/archived when every item in the User Verification section is checked
- Implementation PRs can be merged/closed when implementation tasks are complete, even if User Verification remains
- If implementation is merged but User Verification is pending, create a follow-up GitHub issue labeled `uat`, add it to the Offload project with status `Ready`, and link the plan and merged PR
- Move the plan to `uat` when implementation is merged and only User Verification remains
- Keep the plan in `uat` until User Verification is complete and the `uat` issue is closed
- Active plans tracked in `docs/plans/`
- Completed plans moved to `docs/plans/_archived/`

## Format expectations

- Ordered task list with dependencies
- Clear phases and milestones
- When generating plans in Plan mode, structure implementation work using TDD
  (red → green → refactor) for each phase/slice
- Include explicit test-first tasks before implementation tasks in each phase
- Links to GitHub issues for tracking
  - When creating new issues for plans, add them to the Offload GitHub project
  - Use `gh issue create --project "Offload"` or add via GitHub web UI
  - Apply labels when creating plan issues; never leave a plan issue unlabeled
  - Use `enhancement` for feature/implementation plan issues
  - Use `bug` when the plan is specifically to fix a defect/regression
  - Use `documentation` for docs-only plan issues
  - Any issue labeled `uat` must be placed in project status `Ready` (not
    `Backlog`)
  - Use `ux` as an additional label when the plan primarily targets UX/UI
    behavior
  - **Always add a comment to related issues when a plan is created**, linking to the plan document and summarizing the approach
  - Include plan status, key phases, and next steps in the issue comment
  - When work is merged but User Verification remains, create and link a
    `uat`-labeled issue for verification follow-up and place it in project status `Ready`
  - After plan issue/PR updates, run an issue/project sync audit and fix any
    mismatches before finishing (project membership, required labels, and lane
    alignment such as `In review` only with an open PR)
- References to design docs and PRDs
- Include related design/testing artifacts in plan frontmatter (`related`) when they inform or validate plan execution
- A User Verification section with a checklist; agents must not update or check items in this section
- When plans are added, moved, or archived, update `docs/index.yaml` paths in the same change

## Boundaries

- Does not introduce new requirements (see PRDs)
- Does not make architectural decisions (see ADRs)
- Does not define technical approach (see design docs)
- Must have prerequisite docs complete before acceptance
- Agents must not modify the User Verification section in plans
