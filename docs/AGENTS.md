---
id: docs-agents
type: reference
status: active
owners:
  - Offload
applies_to:
  - agents
last_updated: 2026-01-19
related: []
structure_notes:
  - "Top-level section order: Scope; Documentation Authority Model (MANDATORY); Documentation Safety Rules; Structural Rules; Expected Agent Behavior."
---
# Documentation Agent Guide — Offload

This file defines how agents must navigate, interpret, and modify documentation under `docs/`.

## Scope

- Applies ONLY to documentation in the `docs/` tree
- Overrides any generic agent behavior when working with documentation
- Defers to repository-level `AGENTS.md` for non-doc concerns
- If this file conflicts with repository-level `AGENTS.md` for documentation behavior, THIS FILE WINS

---

## Documentation Authority Model (MANDATORY)

Documentation is organized by intent, with explicit authority.  
Agents must not infer authority from prose, chronology, or filenames.

### Canonical Documentation Areas

1. reference/ — contracts, schemas, terminology, invariants (HIGHEST AUTHORITY)
2. adrs/ — architecture and product decisions (WHY)
3. prds/ — product requirements and scope (WHAT)
4. design/ — technical architecture and implementation approach (HOW)
5. plans/ — sequencing, milestones, execution strategy (WHEN)
6. research/ — exploratory work, spikes, benchmarks (NON-AUTHORITATIVE)

### Authority Resolution Order

When documents conflict, resolve strictly in this order:

reference/
→ adrs/
→ prds/
→ design/
→ plans/
→ research/

If ambiguity remains:

- STOP
- Surface the conflict explicitly
- Do NOT merge intent or guess

---

## Documentation Safety Rules

- Never introduce requirements outside `prds/`
- Never introduce decisions outside `adrs/`
- Never treat `research/` as source of truth
- Design docs must not contradict ADRs or PRDs
- Plans must not introduce scope, requirements, or architecture
- Reference docs must not include rationale or narrative

---

## Structural Rules

- One document = one intent
- Every document MUST include YAML front-matter
- Front-matter format MUST include: `id`, `type`, `status`, `owners`, `applies_to`, `last_updated`, `related`, `structure_notes`
- Additional front-matter keys MAY be used when required by a doc type (for example: `decision-date`, `decision-makers` for ADRs).
- Use stable document IDs
- Prefer explicit links or IDs over prose references
- When referencing other docs in body text, use Markdown links with paths (no bare IDs like `adr-0002`).
- Preserve historical ADRs; deprecate instead of deleting
- Do not collapse multiple documents unless explicitly instructed

---

## Expected Agent Behavior

- Navigate via `docs/index.yaml`
- Prefer reference → adrs → prds when answering questions
- Prefer precision over completeness
- Prefer explicit uncertainty over assumption

This file is authoritative for documentation behavior.
