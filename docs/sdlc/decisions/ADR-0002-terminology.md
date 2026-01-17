<!-- Intent: Record terminology alignment decisions from early iterations so documentation and code use the same vocabulary. -->

# ADR-0002: Terminology Alignment for Capture and Organization

**Status:** Accepted  
**Date:** 2026-01-03  
**Deciders:** Will Conklin  
**Tags:** terminology, product, documentation

## Context

Early prototypes and documentation used multiple names for the same concepts. As the event-sourced capture model solidified, we introduced clearer responsibilities—capture, hand-off, suggestion, placement. We need a single vocabulary to reduce confusion during development and onboarding.

## Decision

Adopt the following canonical terms and use them consistently:

| Canonical term | Rationale |
| --- | --- |
| `CaptureEntry` | Aligns with “capture first” positioning and matches the SwiftData model that stores raw input. |
| `HandOffRequest` / `HandOffRun` | Distinguishes user intent (request) from execution attempts (runs) in the workflow. |
| `Suggestion` / `SuggestionDecision` | Clarifies that AI output is advisory and that user responses are explicit decisions. |
| `Placement` | Represents where accepted suggestions land without overloading “result” terminology. |
| `Plan` | Better reflects lightweight planning over heavyweight project management. |
| `ListEntity` / `ListItem` | Avoids ambiguity with SwiftUI Lists and conveys hierarchy between container and entry. |
| `CommunicationItem` | Name already matches its purpose (calls, emails, messages). |

Unchanged terms retained for consistency and completeness:

| Canonical term | Current usage | Rationale |
| --- | --- | --- |
| `Category` | Stable | Describes lightweight grouping for tasks; no conflicting aliases observed. |
| `Tag` | Stable | Common, user-friendly label semantics that align with many productivity tools. |
| `Task` | Stable | Represents actionable items; already aligned with capture-first language. |
| `VoiceRecordingService` | Stable | Accurately reflects responsibility for capture via audio; no competing names. |
| `CaptureWorkflowService` | Stable | Matches the workflow orchestration role already referenced across docs. |

## Consequences

- All future documentation, UI copy, and schema discussions should use the canonical names above.
- When touching files that still reference older names, prefer renaming to the canonical vocabulary.
- New diagrams and architectural docs should keep capture → hand-off → suggestion → decision → placement as the workflow narrative.

## Alternatives Considered

- **Keep mixed terminology in early docs.** Rejected because it slows onboarding and introduces ambiguity when mapping UI copy to models.  
- **Adopt “Brain Dump” naming everywhere.** Rejected to avoid framing the product around a single capture mode and to keep language neutral for future non-brain-dump entry points.

## Implementation Notes

- Update onboarding, UI strings, and code comments opportunistically to use canonical names.
