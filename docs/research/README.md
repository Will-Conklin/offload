---
id: research-readme
type: research
status: informational
owners:
  - Offload
applies_to:
  - Offload
last_updated: 2026-01-04
related:
  - research-adhd-ux-ui
  - research-color-palettes
  - research-color-scheme-alternatives
  - research-ios-ui-trends-2025
  - research-2026-01-04-main-branch-review
structure_notes:
  - "Section order: Purpose; Authority; Lifecycle; What belongs here; What does not belong here; Canonical documents; Template; Naming."
  - "Keep top-level sections: Purpose; Authority; Lifecycle; What belongs here; What does not belong here; Canonical documents; Template; Naming."
---


# Research

## Purpose

Capture exploratory research, spikes, benchmarks, and reviews.

## Authority

Lowest authority. Research is non-authoritative and must not define requirements, decisions, or plans.

## Lifecycle

```text
in-progress → informational → stale
```

| Status          | Meaning                                      |
| --------------- | -------------------------------------------- |
| `in-progress`   | Research actively being conducted            |
| `informational` | Complete, available for reference            |
| `stale`         | Outdated, may no longer reflect reality      |

## What belongs here

- Exploratory notes, competitive analysis, and UX research.
- Trend studies, benchmarks, and review write-ups.

## What does not belong here

- Product requirements or scope (use prd/).
- Architecture or product decisions (use adr/).
- Implementation plans or schedules (use plans/).

## Canonical documents

- [ADHD-First UX and UI Guidance for Offload](./research-adhd-ux-ui.md)
- [Color Scheme Options for Offload](./research-color-palettes.md)
- [Color Scheme Alternatives for Offload](./research-color-scheme-alternatives.md)
- [iOS UI Trends Research & Recommendations for Offload](./research-ios-ui-trends-2025.md)
- [Code Review: Main Branch - Comprehensive Analysis](./reviews/research-2026-01-04-main-branch-review.md)

## Template

```markdown
---
id: research-{topic}
type: research
status: informational
owners:
  - {name}
applies_to:
  - {area}
last_updated: YYYY-MM-DD
related: []
structure_notes:
  - "Section order: Summary; Findings; Recommendations; Sources."
---

# Research: {Topic}

## Summary

{Brief overview of the research area and objectives}

## Findings

{Key findings from the research}

### Finding 1

{Details}

### Finding 2

{Details}

## Recommendations

{Actionable recommendations based on findings}

- {Recommendation 1}
- {Recommendation 2}

## Sources

- {Source 1}
- {Source 2}
```

## Naming

- Use kebab-case for topic-based research files.
- Use date prefixes for time-bound work (for example, reviews).
- Group specialized research under subfolders like `reviews/`.
