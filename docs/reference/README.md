---
id: reference-readme
type: reference
status: active
owners:
  - Will-Conklin
applies_to:
  - reference
last_updated: 2026-01-22
related:
  - reference-context-aware-ci-pipeline
  - reference-convert-plans-lists
  - reference-ci-path-filters
  - reference-drag-drop-ordering
  - reference-item-search-tags
  - reference-persistent-bottom-tab-bar
  - reference-test-runtime-baselines
depends_on:
  - docs/reference/reference-test-runtime-baselines.md
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
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
- [CI Path Filters and Lane Triggers](./ci/reference-ci-path-filters.md)
- [Context-Aware CI Pipeline](./ci/reference-context-aware-ci-pipeline.md)
- [Persistent Bottom Tab Bar](./reference-persistent-bottom-tab-bar.md)
- [Convert Plans ↔ Lists](./reference-convert-plans-lists.md)
- [Drag & Drop Ordering](./reference-drag-drop-ordering.md)
- [Item Search by Text or Tag](./reference-item-search-tags.md)

## Template

```markdown
---
id: reference-{topic}
type: reference
status: active
owners:
  - TBD  # Never assume; use actual contributor name when known
applies_to:
  - {area}
last_updated: YYYY-MM-DD
related: []
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
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
