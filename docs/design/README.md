---
id: design-readme
type: design
status: accepted
owners:
  - Will-Conklin
applies_to:
  - design
last_updated: 2026-02-15
related:
  - design-voice-capture-testing-guide
  - design-voice-capture-test-results
  - design-context-aware-ci-pipeline
  - design-persistent-bottom-tab-bar
  - design-convert-plans-lists
  - design-drag-drop-ordering
  - design-item-search-tags
  - design-backend-api-privacy-mvp
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Purpose; Authority; Lifecycle; What belongs here; What does not belong here; Canonical documents; Template; Naming."
  - "Keep top-level sections: Purpose; Authority; Lifecycle; What belongs here; What does not belong here; Canonical documents; Template; Naming."
---


# Design

## Purpose

Document technical design and implementation guidance for approved requirements.

## Authority

Below prd. Design defines HOW approved requirements are implemented; it cannot set requirements or decisions and must align with reference and ADRs.

## Lifecycle

```text
proposed → accepted → archived
```

| Status       | Meaning                                    |
| ------------ | ------------------------------------------ |
| `proposed`   | Design being developed, not yet approved   |
| `accepted`   | Approved and authoritative for feature     |
| `archived`   | Superseded or no longer applicable         |

## What belongs here

- Implementation approach, data flow descriptions, and UI behavior specs.
- Testing guides and validation steps tied to features.
- Technical constraints derived from ADRs or PRDs.

## What does not belong here

- Product requirements or scope (use prd/).
- Architecture or product decisions (use adr/).
- Execution timelines or milestones (use plans/).
- Exploratory research (use research/).

## Canonical documents

- [Voice Capture Testing Guide](./testing/design-voice-capture-testing-guide.md)
- [Voice Capture Test Results](./testing/design-voice-capture-test-results.md)
- [Context-Aware CI Pipeline Design](./design-context-aware-ci-pipeline.md)
- [Persistent Bottom Tab Bar Design](./design-persistent-bottom-tab-bar.md)
- [Convert Plans ↔ Lists Design](./design-convert-plans-lists.md)
- [Drag & Drop Ordering Design](./design-drag-drop-ordering.md)
- [Item Search by Text or Tag Design](./design-item-search-tags.md)
- [Backend API + Privacy Constraints MVP](./design-backend-api-privacy-mvp.md)

## Template

```markdown
---
id: design-{feature-name}
type: design
status: proposed
owners:
  - TBD  # Never assume; use actual contributor name when known
applies_to:
  - {area}
last_updated: YYYY-MM-DD
related:
  - prd-0001-{feature-name}
  - adr-0001-{decision-title}
depends_on:
  - docs/prds/prd-0001-{feature-name}.md
  - docs/adrs/adr-0001-{decision-title}.md
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Overview; Architecture; Data Flow; UI Behavior; Testing; Constraints."
---

# Design: {Feature Name}

## Overview

{Brief description of the technical design and its relationship to approved
requirements}

## Architecture

{High-level architecture, components, and their interactions}

## Data Flow

{How data moves through the system}

## UI Behavior

{Detailed UI behavior specifications and states}

## Testing

{Testing approach and validation steps}

## Constraints

{Technical constraints derived from ADRs or PRDs}
```

## Naming

- Use kebab-case with a clear feature or system name.
- Group specialized areas under subfolders like `testing/`.
