---
id: reference-testing-readme
type: reference
status: active
owners:
  - Offload
applies_to:
  - testing
last_updated: 2026-01-17
related:
  - reference-test-runtime-baselines
depends_on:
  - docs/reference/reference-test-runtime-baselines.md
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Purpose; Authority; What belongs here; What does not belong here; Canonical documents; Naming."
  - "Keep top-level sections: Purpose; Authority; What belongs here; What does not belong here; Canonical documents; Naming."
---


# Testing

## Purpose

Store authoritative testing baselines and constraints.

## Authority

Reference-level authority. These docs define baseline numbers and constraints; they should not include testing steps or analysis.

## What belongs here

- Runtime baselines, thresholds, and environment definitions.
- Authoritative test command references.

## What does not belong here

- Testing guides or checklists (use design/testing/).
- Test result write-ups or reviews (use design/ or research/).
- Requirements or decisions (use prd/ or adr/).

## Canonical documents

- [Test Runtime Baselines](./reference-test-runtime-baselines.md)

## Naming

- Use descriptive filenames like `reference-test-runtime-baselines.md` or `thresholds.md`.
- Keep names stable to preserve references from plans and CI docs.
