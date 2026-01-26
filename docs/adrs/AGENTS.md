---
id: adrs-agents
type: reference
status: active
owners:
  - Will-Conklin
applies_to:
  - agents
  - adrs
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
# ADR Agent Guide

This file provides agent-only instructions for documentation in `docs/adrs/`.
README files are informational for users.

## Scope

- Applies to `docs/adrs/**`
- Defers to `docs/AGENTS.md` for global documentation rules

## Purpose

Document significant architectural and product decisions with rationale (WHY).

## Contains

- Technology choices (frameworks, libraries, tools)
- Architectural patterns and approaches
- Product direction decisions
- Trade-off analysis
- Decision context and constraints
- Alternatives considered and rejected

## When to create

- Before making significant architectural choices
- When choosing between multiple valid approaches
- When decisions impact multiple features or systems
- When trade-offs need to be documented for future reference
- Only when actual decisions need to be made (not required for every feature)

## Lifecycle

- Created after research phase, before design phase
- Status: proposed -> accepted -> superseded/deprecated
- Never deleted (preserve historical decisions)
- Supersede with new ADRs when decisions change

## Format expectations

- Standard ADR format: Context, Decision, Consequences
- Include alternatives considered
- Document trade-offs explicitly
- Link to related ADRs, PRDs, and research

## Boundaries

- Does not define requirements (see PRDs)
- Does not include implementation steps (see design docs or plans)
- Does not replace reference docs (contracts live in reference/)
