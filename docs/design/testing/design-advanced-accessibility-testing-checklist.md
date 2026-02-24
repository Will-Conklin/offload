---
id: design-advanced-accessibility-testing-checklist
type: design
status: draft
owners:
  - Will-Conklin
applies_to:
  - testing
  - accessibility
  - ux
  - ios
last_updated: 2026-02-21
related:
  - plan-advanced-accessibility
  - plan-ux-accessibility-audit-fixes
  - adr-0003-adhd-focused-ux-ui-guardrails
  - design-manual-testing-checklist
depends_on:
  - docs/plans/plan-advanced-accessibility.md
  - docs/adrs/adr-0003-adhd-focused-ux-ui-guardrails.md
supersedes: []
accepted_by: null
accepted_at: null
related_issues:
  - https://github.com/Will-Conklin/Offload/issues/108
structure_notes:
  - "Section order: Purpose; Scope; Preconditions; Device Matrix; Checklist; Evidence; Exit Criteria."
  - "Keep top-level sections: Purpose; Scope; Preconditions; Device Matrix; Checklist; Evidence; Exit Criteria."
---

# Advanced Accessibility Testing Checklist

## Purpose

Provide a repeatable, on-device validation checklist for advanced accessibility
behavior introduced in `plan-advanced-accessibility`, with emphasis on
VoiceOver/Switch Control action parity and Dynamic Type interaction sizing.

## Scope

- Capture cards (`CaptureItemCard`) accessibility actions.
- Organize collection detail rows (`CollectionDetailItemRows`) accessibility actions.
- Organize collection cards (`OrganizeCollectionCards`) accessibility actions.
- Dynamic Type sizing behavior for action controls and drop zones in organize
  flows.

## Preconditions

- Install a build containing:
  - `AdvancedAccessibilityActionPolicy`
  - `AdvancedAccessibilityLayoutPolicy`
  - Conditional optional accessibility actions (`accessibilityActionIf`)
- Have at least:
  - one capture item
  - one list collection
  - one plan collection
  - one linked item in a collection (for "Open linked collection" action)
- Enable and test these accessibility settings:
  - VoiceOver
  - Switch Control
  - Dynamic Type at both standard and accessibility sizes
  - Reduce Motion (ON and OFF)

## Device Matrix

| Device | OS | Build | Tester | Date | Result |
| --- | --- | --- | --- | --- | --- |
| iPhone | iOS | Debug/TestFlight | TBD | YYYY-MM-DD | Pass/Fail |
| iPad | iPadOS | Debug/TestFlight | TBD | YYYY-MM-DD | Pass/Fail |

## Checklist

### VoiceOver and Switch Control Action Parity

- [ ] Capture card exposes actions: Complete, Delete, Star/Unstar, Move to Plan,
      Move to List.
- [ ] Capture card Star action toggles correctly and label updates between Star
      and Unstar.
- [ ] Collection detail row exposes actions: Delete, Edit item/Open linked
      collection, Star/Unstar.
- [ ] Linked collection row action says "Open linked collection" and navigates
      to linked destination.
- [ ] Non-linked row action says "Edit item" and opens edit flow.
- [ ] Organize collection card exposes Delete and Star/Unstar actions.
- [ ] Convert action appears only for cards where conversion is available.
- [ ] Move up/down actions appear only where corresponding handlers exist
      (no inert/no-op actions).

### Dynamic Type and Interaction Sizing

- [ ] At default Dynamic Type, controls remain at baseline sizing and do not
      clip content.
- [ ] At accessibility Dynamic Type sizes, chevron/action controls visibly
      increase touch size.
- [ ] At accessibility Dynamic Type sizes, drop zone idle/target heights increase
      and remain visually aligned.
- [ ] Drag and drop remains functional at accessibility Dynamic Type sizes.
- [ ] Swipe and tap gesture targets remain usable at accessibility Dynamic Type
      sizes.

### Reduce Motion and Interaction Integrity

- [ ] With Reduce Motion ON, action behaviors remain functional and predictable.
- [ ] With Reduce Motion OFF, animation behavior remains smooth with no jitter.
- [ ] No accessibility action becomes unavailable due to motion setting changes.

## Evidence

- Record screenshots or short screen captures for:
  - VoiceOver actions on capture card
  - VoiceOver actions on collection detail row (linked and non-linked)
  - VoiceOver actions on organize collection card (with and without convert)
  - Dynamic Type accessibility size rendering for organize rows/cards
- Link evidence in issue
  [#108](https://github.com/Will-Conklin/Offload/issues/108).

## Exit Criteria

- All checklist items pass on at least one iPhone and one iPad.
- Any failures have linked follow-up issues with labels and project status set.
- `plan-advanced-accessibility` Slice 2 refactor validation task can be marked
  complete once evidence is attached and reviewed.
