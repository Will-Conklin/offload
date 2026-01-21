---
id: reference-readme
type: reference
status: active
owners:
  - Offload
applies_to:
  - Offload
last_updated: 2026-01-17
related:
  - reference-test-runtime-baselines
structure_notes:
  - "Section order: Purpose; Authority; Lifecycle; What belongs here; What does not belong here; Canonical documents; Template; Naming."
  - "Keep top-level sections: Purpose; Authority; Lifecycle; What belongs here; What does not belong here; Canonical documents; Template; Naming."
---


# Reference

## Purpose

Provide authoritative contracts, schemas, terminology, and invariants.

## Authority

Highest authority. Reference docs define source-of-truth facts and must avoid rationale, narrative, or implementation details.

## Lifecycle

```text
draft → active → deprecated
```

| Status       | Meaning                                   |
| ------------ | ----------------------------------------- |
| `draft`      | Being defined, not yet authoritative      |
| `active`     | Authoritative source of truth             |
| `deprecated` | Superseded or no longer applicable        |

## What belongs here

- Glossaries, schemas, data definitions, and invariants.
- Authoritative baselines or thresholds.

## What does not belong here

- Decision rationale (use adr/).
- Product requirements or scope (use prd/).
- Technical design or implementation guidance (use design/).
- Plans or schedules (use plans/).

## Canonical documents

- [Test Runtime Baselines](./testing/reference-test-runtime-baselines.md)

## Template

```markdown
---
id: reference-{topic}
type: reference
status: active
owners:
  - {name}
applies_to:
  - {area}
last_updated: YYYY-MM-DD
related: []
structure_notes:
  - "Reference docs must avoid rationale or narrative."
---

# {Topic}

## Definition

{Clear, authoritative definition}

## Schema

{Data structure, fields, types, constraints}

## Invariants

{Rules that must always hold}

## Examples

{Concrete examples if helpful}
```

## Naming

- Use stable, descriptive nouns for filenames.
- Avoid dates unless the document is inherently time-bound.
