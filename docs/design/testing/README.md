---
id: design-testing-readme
type: design
status: active
owners:
  - Offload
applies_to:
  - testing
last_updated: 2026-01-19
related:
  - design-v1-manual-testing-checklist
  - design-v1-manual-testing-results
  - design-voice-capture-testing-guide
  - design-voice-capture-test-results
structure_notes:
  - "Section order: Purpose; Authority; What belongs here; What does not belong here; Canonical documents; Naming."
  - "Keep top-level sections: Purpose; Authority; What belongs here; What does not belong here; Canonical documents; Naming."
---


# Testing

## Purpose

Capture testing guides and results tied to design and implementation.

## Authority

Design-level authority. These docs explain how to validate features but do not define requirements or baselines.

## What belongs here

- Feature-level test guides and checklists.
- Test result templates or summaries for implemented features.

## What does not belong here

- Runtime baselines or performance thresholds (use reference/testing/).
- Requirements or scope definitions (use prd/).
- Architecture decisions (use adr/).

## Canonical documents

- [V1 Manual Testing Checklist](./design-v1-manual-testing-checklist.md)
- [V1 Manual Testing Results](./design-v1-manual-testing-results.md)
- [Voice Capture Testing Guide](./design-voice-capture-testing-guide.md)
- [Voice Capture Test Results](./design-voice-capture-test-results.md)

## Naming

- Use `feature-name.md` for test guides and `feature-name-results.md` for results.
- Keep filenames stable once referenced in plans or PRDs.
