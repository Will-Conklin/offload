---
id: docs-agents
type: reference
status: active
owners:
  - Will-Conklin
applies_to:
  - agents
last_updated: 2026-02-14
related: []
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Agent guidance only."
  - "Top-level section order: Scope; Documentation Authority Model (MANDATORY); Directory-Level Agent Guides; Documentation Safety Rules; Structural Rules; Documentation Workflow Dependencies; Expected Agent Behavior."
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
6. discovery/ — initial feature discovery spikes prior to PRD creation (NON-AUTHORITATIVE)
7. research/ — exploratory work, spikes, benchmarks (NON-AUTHORITATIVE)

### Directory-Level Agent Guides

Doc-specific agent instructions live in directory-level `AGENTS.md` files.  
README files are informational for users and do not override agent guidance.

- `docs/reference/AGENTS.md`
- `docs/adrs/AGENTS.md`
- `docs/prds/AGENTS.md`
- `docs/design/AGENTS.md`
- `docs/plans/AGENTS.md`
- `docs/research/AGENTS.md`
- `docs/discovery/AGENTS.md` (when the directory exists)

### Authority Resolution Order

When documents conflict, resolve strictly in this order:

reference/
→ adrs/
→ prds/
→ design/
→ plans/
→ discovery/
→ research/

If ambiguity remains:

- STOP
- Surface the conflict explicitly
- Do NOT merge intent or guess

---

## Documentation Safety Rules

- Never introduce requirements outside `prds/`
- Never introduce decisions outside `adrs/`
- Never treat `discovery/` or `research/` as source of truth
- Design docs must not contradict ADRs or PRDs
- Plans must not introduce scope, requirements, or architecture
- Reference docs must be factual, may include implemented contractual identifiers, and must avoid rationale or implementation approach
- Accepted documents must never be updated without explicit user approval

---

## Structural Rules

- One document = one intent
- Every document MUST include YAML frontmatter (see [Frontmatter Schema Reference](reference/reference-frontmatter-schema.md))
- Frontmatter is for agent parsing only; non-agent automation must not parse or depend on it
- Document metadata must live only in YAML frontmatter; do not add metadata blocks to the body
- AGENTS.md files provide agent guidance; README.md files are informational for users
- Use stable document IDs
- Prefer explicit links or IDs over prose references
- When referencing other docs in body text, use Markdown links with paths (no bare IDs like `adr-0002`).
- Preserve historical ADRs; deprecate instead of deleting
- Do not collapse multiple documents unless explicitly instructed
- Archived docs can be moved to directory-level `_archived/` directories; create them when missing
- When moving, renaming, or archiving documentation files, update `docs/index.yaml` in the same change so all `path` entries resolve

### Owner Assignment Rules

- **NEVER assume or infer document ownership**
- Use `TBD` if the owner is not explicitly known
- Owner values MUST be individual contributor names (e.g., `Will-Conklin`), never role-based (e.g., "design", "product")
- Do not use generic values like "Offload" unless explicitly specified for meta-documentation

---

## Documentation Workflow Dependencies

Documentation must be created and accepted in dependency order before implementation:

1. **discovery/** → exploratory spikes (optional, non-authoritative)
2. **prds/** → requirements definition
3. **research/** → investigation to inform decisions (optional, non-authoritative)
4. **adrs/** → architectural/product decisions
5. **design/** → technical implementation approach
6. **plans/** → execution sequencing
7. **reference/** → contracts, schemas, terminology (created during/after implementation)

### Dependency Rules

- Designs MUST NOT be accepted if they depend on unmade decisions (missing ADRs)
- Plans MUST NOT be accepted if they depend on incomplete designs
- Implementation MUST NOT start until the required documentation chain is complete
- Agents MUST surface missing prerequisite documentation and block progression

---

## Expected Agent Behavior

- Navigate via `docs/index.yaml`
- Keep `docs/index.yaml` synchronized with documentation adds/moves/archives before finishing
- Prefer reference → adrs → prds when answering questions
- Prefer precision over completeness
- Prefer explicit uncertainty over assumption
- Enforce documentation workflow dependencies before allowing implementation

This file is authoritative for documentation behavior.
