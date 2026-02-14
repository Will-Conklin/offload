---
id: research-2026-02-14-docs-plan-coverage-review
type: research
status: completed
owners:
  - Will-Conklin
applies_to:
  - docs
  - plans
last_updated: 2026-02-14
related:
  - plans-readme
  - docs-agents
  - prd-0001-product-requirements
  - prd-0002-persistent-bottom-tab-bar
  - prd-0003-convert-plans-lists
  - prd-0004-drag-drop-ordering
  - prd-0005-item-search-tags
  - prd-0006-context-aware-ci-pipeline
  - prd-0007-smart-task-breakdown
  - prd-0008-brain-dump-compiler
  - prd-0009-recurring-task-intelligence
  - prd-0010-tone-assistant
  - prd-0011-executive-function-prompts
  - prd-0012-decision-fatigue-reducer
  - prd-0013-pricing-limits
  - design-voice-capture-testing-guide
  - design-voice-capture-test-results
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Scope Reviewed; Method; Coverage Summary; Findings; Recommendations; Follow-up Checklist."
---

# Docs → Plan Coverage Review (2026-02-14)

## Scope Reviewed

- Entire `docs/` tree with emphasis on authoritative artifacts and whether each documented component is represented by at least one plan entry in `docs/plans/` (active or archived).
- Included directories: `prds/`, `adrs/`, `design/`, `reference/`, `plans/`, `discovery/`, `research/`.

## Method

1. Enumerate all documentation artifacts under `docs/`.
2. Treat each PRD/design/reference feature document as a "component signal".
3. Match component signals to plan coverage using:
   - explicit `related` IDs in plan frontmatter,
   - explicit `depends_on` links in plan frontmatter,
   - topic-level parity when a plan exists for the same feature area.
4. Flag gaps where no active/archived plan currently accounts for the component.

## Coverage Summary

- **PRD components:** 13/13 accounted for by existing plans.
- **Design components (feature/design docs):** 7/9 explicitly accounted for by existing plans.
- **Potential uncovered components:** 2 voice-capture testing artifacts.
- **Plan catalog hygiene:** several plan files exist but are not indexed in `docs/index.yaml` (navigation gap, not scope gap).

## Findings

### 1) Core product and roadmap features are accounted for

The following feature areas all have plan coverage:

- Persistent Bottom Tab Bar (archived plan).
- Convert Plans ↔ Lists.
- Drag & Drop Ordering.
- Item Search by Text/Tag.
- Context-Aware CI Pipeline (archived plan).
- AI/assistant feature cluster (smart breakdown, brain dump compiler, recurring intelligence, tone assistant, executive prompts, decision fatigue, pricing/limits) via `plan-ai-organization-flows` and `plan-ai-pricing-limits` plus backend/privacy dependency planning.

### 2) Voice capture testing artifacts do not have explicit plan linkage

The following accepted design/testing docs do not currently map to a dedicated plan by frontmatter linkage:

- `docs/design/testing/design-voice-capture-testing-guide.md`
- `docs/design/testing/design-voice-capture-test-results.md`

There is related remediation work (`plan-fix-voice-recording-threading`), but the plan does not explicitly reference these artifacts in frontmatter. This is the strongest candidate for an "unaccounted component" depending on desired strictness.

### 3) Documentation navigation index is incomplete for plans

`docs/index.yaml` currently omits multiple active and archived plan files. This is a discoverability/governance issue and can mask coverage that already exists.

## Recommendations

1. **Resolve the voice-capture gap explicitly** (pick one):
   - add `design-voice-capture-testing-guide` and `design-voice-capture-test-results` to `related` in `plan-fix-voice-recording-threading`, or
   - create a dedicated voice-capture stabilization/testing plan if scope is broader than threading.
2. **Update `docs/index.yaml`** to include all active plan files and omitted archived plan files to keep docs navigation authoritative for agents and humans.
3. For future docs, enforce a lightweight rule: any new feature-focused design/testing doc should declare plan linkage (`depends_on` or reciprocal `related`) at creation time.

## Follow-up Checklist

- [ ] Decide whether voice-capture testing is fully covered by existing remediation plan.
- [ ] If yes, update plan frontmatter links for traceability.
- [ ] If no, create a dedicated plan and add it to `docs/index.yaml`.
- [ ] Re-run this coverage review after index synchronization.
