---
id: prds-agents
type: reference
status: active
owners:
  - Will-Conklin
applies_to:
  - agents
  - prds
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
# PRD Agent Guide

This file provides agent-only instructions for documentation in `docs/prds/`.
README files are informational for users.

## Scope

- Applies to `docs/prds/**`
- Defers to `docs/AGENTS.md` for global documentation rules

## Purpose

Define product requirements, scope, and success criteria (WHAT).

## Contains

- Feature requirements and scope
- User needs and problems being solved
- Success criteria and metrics
- User stories or use cases
- Acceptance criteria
- Non-functional requirements

## When to create

- After initial discovery phase
- Before design work begins
- When defining new features or major enhancements
- When scope needs formal definition

## Lifecycle

- Created after discovery, before ADRs and design
- Status: proposed -> accepted -> implemented/archived
- Updated when requirements change significantly
- Archived when implementation is complete

## Format expectations

- Clear problem statement
- User-focused requirements (not implementation details)
- Measurable success criteria
- Scope boundaries (what is in or out)
- Links to discovery docs that informed requirements

## Boundaries

- Does not include technical decisions (see ADRs)
- Does not include implementation approach (see design docs)
- Does not include execution strategy (see plans)
- Does not treat discovery or research as requirements
