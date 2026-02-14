---
id: research-readme
type: research
status: active
owners:
  - Will-Conklin
applies_to:
  - research
last_updated: 2026-01-25
related:
  - research-adhd-ux-ui
  - research-color-palettes
  - research-color-scheme-alternatives
  - research-ios-ui-trends-2025
  - research-2026-01-04-main-branch-review
  - research-2026-02-14-docs-plan-coverage-review
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
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
active → completed
```

| Status      | Meaning                                      |
| ----------- | -------------------------------------------- |
| `active`    | Research actively being conducted            |
| `completed` | Complete, available for reference            |

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
- [On-Device AI Feasibility for Offload](./research-on-device-ai-feasibility.md)
- [Offline AI Quota Enforcement](./research-offline-ai-quota-enforcement.md)
- [Privacy Implications of Learning from User Data](./research-privacy-learning-user-data.md)
- [Code Review: Main Branch - Comprehensive Analysis](./reviews/research-2026-01-04-main-branch-review.md)
- [Docs → Plan Coverage Review (2026-02-14)](./reviews/research-2026-02-14-docs-plan-coverage-review.md)

## Template

```markdown
---
id: research-{topic}
type: research
status: active
owners:
  - TBD  # Never assume; use actual contributor name when known
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
