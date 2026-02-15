---
id: design-agents
type: reference
status: active
owners:
  - Will-Conklin
applies_to:
  - agents
  - design
last_updated: 2026-02-14
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
# Design Agent Guide

This file provides agent-only instructions for documentation in `docs/design/`.
README files are informational for users.

## Scope

- Applies to `docs/design/**`
- Defers to `docs/AGENTS.md` for global documentation rules

## Purpose

Document technical architecture and implementation approach (HOW).

## Contains

- System architecture diagrams
- Component structure and relationships
- Data flow and state management
- Integration points and APIs
- Error handling strategies
- Implementation approach

## When to create

- After PRDs and ADRs are accepted
- Before creating implementation plans
- When technical approach needs documentation
- For complex features requiring architectural clarity

## Lifecycle

- Created after ADRs, before plans
- Status: proposed -> accepted -> archived
- Must not contradict ADRs or PRDs
- Updated when implementation approach changes
- Archived when implementation is complete

## Format expectations

- Architecture diagrams (Mermaid preferred)
- Component breakdown
- Data models and relationships
- Integration specifications
- Links to related ADRs and PRDs
- Feature-focused design/testing docs must link to implementation plans via frontmatter (`related` plan IDs and/or `depends_on` plan paths)

## Boundaries

- Does not make architectural decisions (see ADRs)
- Does not define requirements (see PRDs)
- Does not include execution sequencing (see plans)
- Must align with accepted ADRs
