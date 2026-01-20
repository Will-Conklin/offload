---
id: adr-0003-adhd-focused-ux-ui-guardrails
type: architecture-decision
status: accepted
owners:
  - design
  - ios
applies_to:
  - architecture
  - adhd
  - focused
  - ux
  - ui
  - guardrails
last_updated: 2026-01-05
related: []
structure_notes:
  - "Section order: Context; Decision; Consequences; Alternatives Considered; Implementation Notes; References; Revision History."
  - "Keep top-level sections: Context; Decision; Consequences; Alternatives Considered; Implementation Notes; References; Revision History."
decision-date: 2026-01-05
decision-makers:
  - design
  - ios
---

<!-- Intent: Capture ADHD-focused UX/UI guardrail decisions to steer Offload's design and implementation. -->

# adr-0003: ADHD-Focused UX/UI Guardrails

**Status:** Accepted  
**Decision Date:** 2026-01-05  
**Deciders:** Design, iOS

## Context

Recent research synthesized ADHD-friendly UX and UI principles for Offload. To make this guidance actionable and traceable, we need explicit decisions that constrain design and implementation across capture, inbox, organize flows, and the design system.

## Decision

1. **Capture-first default:** Offload will provide a persistent capture control with immediate-save behavior; organizing is optional and secondary in the initial flow.
2. **Undo over confirmation:** Destructive and move actions will favor undo banners/snackbars instead of blocking confirmation modals, except for destructive batch actions.
3. **Calm visual system:** The design system will define a restrained palette (base + primary accent + secondary accent) with accessible contrast, minimal simultaneous colors, and consistent spacing tokens to reduce visual noise.
4. **Predictable navigation:** Core areas (Inbox, Capture, Organize, Settings) remain one tap away via the main tab shell. Capture uses sheets; editing uses full screens. Swipe actions are mirrored with visible buttons.
5. **Gentle organization prompts:** Organization cues appear as non-blocking chips/cards (e.g., "Ready to organize"), with optional snooze/dismiss—no urgency language or forced flows.
6. **Accessibility-first:** All flows will respect Dynamic Type, Reduce Motion, and 44×44 pt tap targets; focus states combine color and stroke weight for clarity.

These guardrails reduce decision fatigue, support working memory limits, and lower anxiety around irreversible actions—key needs for people with ADHD or poor executive function. A calm visual hierarchy and predictable navigation lower cognitive load, while gentle prompts encourage organization without pressure.

## Consequences

- Design tokens and component APIs must encode the palette, spacing, and focus-state rules.
- Capture surfaces must auto-focus inputs and save by default; "Organize now" remains optional.
- Undo infrastructure is required across Inbox and Organize flows, influencing data and UI layers.
- Navigation patterns should avoid deep stacks; new features must fit within the tab shell or shallow sheets.
- Reminders and prompts must allow snooze/dismiss and avoid alarmist language.

## Alternatives Considered

- None documented.

## Implementation Notes

- Ensure design tokens encode palette, spacing, and focus states.
- Validate capture and undo flows in usability testing.

## References

- None.

## Revision History

| Version | Date       | Notes            |
| ------- | ---------- | ---------------- |
| 1.0     | 2026-01-05 | Initial decision |
