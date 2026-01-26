---
id: adr-0002-terminology-alignment-for-capture-and-organization
type: architecture-decision
status: accepted
owners:
  - Will-Conklin
applies_to:
  - terminology
  - product
  - documentation
last_updated: 2026-01-20
related: []
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Context; Decision; Consequences; Alternatives Considered; Implementation Notes; References; Revision History."
  - "Keep top-level sections: Context; Decision; Consequences; Alternatives Considered; Implementation Notes; References; Revision History."
decision-date: 2026-01-03
decision-makers:
  - Will-Conklin
---

<!-- Intent: Record terminology alignment decisions from early iterations so documentation and code use the same vocabulary. -->

# adr-0002: Terminology Alignment for Capture and Organization

**Status:** Accepted  
**Decision Date:** 2026-01-03  
**Deciders:** Will Conklin  
**Tags:** terminology, product, documentation

## Context

Early prototypes and documentation used multiple names for the same concepts. As the event-sourced capture model solidified, we introduced clearer responsibilities—capture, hand-off, suggestion, placement. We need a single vocabulary to reduce confusion during development and onboarding.

## Decision

Adopt the following canonical terms and use them consistently.

> **Note (Jan 19, 2026):** The January 13, 2026 UI overhaul consolidated the
> data model significantly. Many terms below are now **superseded** - see the
> updated table for current status.

### Current terminology (Jan 2026)

| Term             | Status   | Notes                                          |
| ---------------- | -------- | ---------------------------------------------- |
| `Item`           | Active   | Unified model for captures, tasks, and links   |
| `Collection`     | Active   | Unified container for plans and lists          |
| `CollectionItem` | Active   | Join table for Item ↔ Collection relationship  |
| `Tag`            | Active   | User-defined labels referenced by `Item.tags`  |
| `Plan`           | UI term  | Collection with `isStructured = true`          |
| `List`           | UI term  | Collection with `isStructured = false`         |

### Superseded terminology (pre-consolidation)

| Original term                      | Replaced by                           |
| ---------------------------------- | ------------------------------------- |
| `CaptureEntry`                     | `Item` with `type = nil`              |
| `ListEntity` / `ListItem`          | `Collection` / `CollectionItem`       |
| `CommunicationItem`                | Removed (feature cut)                 |
| `Category`                         | Removed (unused)                      |
| `HandOffRequest` / `HandOffRun`    | Deferred (AI features)                |
| `Suggestion` / `SuggestionDecision`| Deferred (AI features)                |
| `Placement`                        | Deferred (AI features)                |

### Stable terms (unchanged)

| Term                   | Status | Notes                                           |
| ---------------------- | ------ | ----------------------------------------------- |
| `Tag`                  | Stable | User-friendly label semantics                   |
| `VoiceRecordingService`| Stable | Capture via audio                               |

## Consequences

- All future documentation, UI copy, and schema discussions should use the canonical names above.
- When touching files that still reference older names, prefer renaming to the canonical vocabulary.
- New diagrams and architectural docs should keep capture → hand-off → suggestion → decision → placement as the workflow narrative.

## Alternatives Considered

- **Keep mixed terminology in early docs.** Rejected because it slows onboarding and introduces ambiguity when mapping UI copy to models.  
- **Adopt “Brain Dump” naming everywhere.** Rejected to avoid framing the product around a single capture mode and to keep language neutral for future non-brain-dump entry points.

## Implementation Notes

- Update onboarding, UI strings, and code comments opportunistically to use canonical names.

## References

- None.

## Revision History

| Version | Date       | Notes                                              |
| ------- | ---------- | -------------------------------------------------- |
| 1.0     | 2026-01-03 | Initial decision                                   |
| 1.1     | 2026-01-19 | Updated for Jan 13 data model consolidation        |
| 1.2     | 2026-01-20 | Clarified tag references as relationships          |
