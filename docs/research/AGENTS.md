---
id: research-agents
type: reference
status: active
owners:
  - Will-Conklin
applies_to:
  - agents
  - research
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
# Research Agent Guide

This file provides agent-only instructions for documentation in `docs/research/`.
README files are informational for users.

## Scope

- Applies to `docs/research/**`
- Defers to `docs/AGENTS.md` for global documentation rules

## Purpose

Document spikes, experiments, and benchmarks to inform decisions (non-authoritative).

## Contains

- Technical spikes and experiments
- Performance benchmarks
- Library or tool evaluations
- Proofs of concept
- Investigation findings
- Data to inform ADRs

## When to create

- After PRD, before ADRs
- When decisions need data or evidence
- When exploring technical unknowns
- When validating approaches

## Lifecycle

- Created as needed to inform decisions
- Status: active -> completed
- Non-authoritative (never treated as source of truth)
- Archived after informing ADRs or design docs

## Format expectations

- Experimental and data-driven
- Clear methodology
- Findings and conclusions
- Links to ADRs or design docs informed by research

## Boundaries

- Does not define requirements (see PRDs)
- Does not make decisions (see ADRs)
- Does not replace initial discovery (see discovery/)
- Findings must be formalized in ADRs or design docs to become authoritative
