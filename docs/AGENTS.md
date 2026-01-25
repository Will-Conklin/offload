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
  - "Agent guidance only."
  - "Top-level section order: Scope; Documentation Authority Model (MANDATORY); Documentation Safety Rules; Structural Rules; Documentation Workflow Dependencies; Expected Agent Behavior."
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

### Document Type Definitions

#### 1. reference/ (HIGHEST AUTHORITY)

**Purpose**: Define contracts, schemas, APIs, terminology, and invariants that code must follow.

**Contains**:

- API contracts and endpoint definitions
- Data schemas and model specifications
- Type definitions and interfaces
- Terminology glossaries
- System invariants and constraints
- Configuration contracts

**When to create**:

- During implementation when contracts are finalized
- After API endpoints are stabilized
- When schemas/models are established
- As terminology becomes standardized

**Lifecycle**:

- Created during/after implementation at appropriate points
- Updated when contracts change (with versioning)
- NEVER deleted (deprecate and version instead)
- Must remain synchronized with actual implementation

**Format expectations**:

- No rationale or narrative (factual only)
- Machine-readable where possible (JSON Schema, OpenAPI, etc.)
- Clear versioning for breaking changes
- Examples of valid usage

**Boundaries**:

- Does NOT include "why" decisions were made (see ADRs)
- Does NOT include implementation details (see design docs)
- Does NOT include feature requirements (see PRDs)

---

#### 2. adrs/ (Architecture Decision Records)

**Purpose**: Document significant architectural and product decisions with rationale (WHY).

**Contains**:

- Technology choices (frameworks, libraries, tools)
- Architectural patterns and approaches
- Product direction decisions
- Trade-off analysis
- Decision context and constraints
- Alternatives considered and rejected

**When to create**:

- Before making significant architectural choices
- When choosing between multiple valid approaches
- When decisions impact multiple features or systems
- When trade-offs need to be documented for future reference
- ONLY when actual decisions need to be made (not required for every feature)

**Lifecycle**:

- Created after research phase, before design phase
- Status: proposed → accepted → superseded/deprecated
- NEVER deleted (preserve historical decisions)
- Supersede with new ADRs when decisions change

**Format expectations**:

- Standard ADR format: Context, Decision, Consequences
- Include alternatives considered
- Document trade-offs explicitly
- Link to related ADRs, PRDs, and research

**Boundaries**:

- Does NOT define requirements (see PRDs)
- Does NOT include implementation steps (see design docs or plans)
- Does NOT replace reference docs (contracts live in reference/)

---

#### 3. prds/ (Product Requirements Documents)

**Purpose**: Define product requirements, scope, and success criteria (WHAT).

**Contains**:

- Feature requirements and scope
- User needs and problems being solved
- Success criteria and metrics
- User stories or use cases
- Acceptance criteria
- Non-functional requirements

**When to create**:

- After initial discovery phase
- Before design work begins
- When defining new features or major enhancements
- When scope needs formal definition

**Lifecycle**:

- Created after discovery, before ADRs/design
- Status: draft → accepted → implemented/archived
- Updated when requirements change significantly
- Archived when implementation is complete

**Format expectations**:

- Clear problem statement
- User-focused requirements (not implementation details)
- Measurable success criteria
- Scope boundaries (what's in/out)
- Links to discovery docs that informed requirements

**Boundaries**:

- Does NOT include technical decisions (see ADRs)
- Does NOT include implementation approach (see design docs)
- Does NOT include execution strategy (see plans)
- Does NOT treat discovery/research as requirements

---

#### 4. design/ (Technical Design Documents)

**Purpose**: Document technical architecture and implementation approach (HOW).

**Contains**:

- System architecture diagrams
- Component structure and relationships
- Data flow and state management
- Integration points and APIs
- Error handling strategies
- Implementation approach

**When to create**:

- After PRDs and ADRs are accepted
- Before creating implementation plans
- When technical approach needs documentation
- For complex features requiring architectural clarity

**Lifecycle**:

- Created after ADRs, before plans
- Must not contradict ADRs or PRDs
- Updated when implementation approach changes
- Archived when implementation is complete

**Format expectations**:

- Architecture diagrams (Mermaid preferred)
- Component breakdown
- Data models and relationships
- Integration specifications
- Links to related ADRs and PRDs

**Boundaries**:

- Does NOT make architectural decisions (see ADRs)
- Does NOT define requirements (see PRDs)
- Does NOT include execution sequencing (see plans)
- MUST align with accepted ADRs

---

#### 5. plans/ (Implementation Plans)

**Purpose**: Define execution sequencing, milestones, and task breakdown (WHEN).

**Contains**:

- Task breakdown and dependencies
- Implementation phases and milestones
- Work sequencing and order
- Effort estimates (when needed)
- Risk mitigation strategies
- Testing and validation approach

**When to create**:

- After PRDs, ADRs, and design docs are accepted
- Before implementation begins
- When execution strategy needs coordination
- For tracking progress on complex features

**Lifecycle**:

- Created after design docs, before implementation
- Status: draft → accepted → in-progress → completed
- Updated as implementation progresses
- Active plans tracked in `docs/plans/`
- Completed plans moved to `docs/plans/_archived/`

**Format expectations**:

- Ordered task list with dependencies
- Clear phases/milestones
- Links to GitHub issues for tracking
- References to design docs and PRDs

**Boundaries**:

- Does NOT introduce new requirements (see PRDs)
- Does NOT make architectural decisions (see ADRs)
- Does NOT define technical approach (see design docs)
- MUST have prerequisite docs complete before acceptance

---

#### 6. discovery/ (Feature Discovery Spikes)

**Purpose**: Explore feature possibilities and gather context before formal requirements (NON-AUTHORITATIVE).

**Contains**:

- Initial feature exploration
- Problem space investigation
- User need discovery
- Competitive analysis
- Feasibility assessment
- Open questions and uncertainties

**When to create**:

- At the very beginning of feature exploration
- Before PRD creation
- When problem space is unclear
- When feasibility is uncertain

**Lifecycle**:

- Created first, before PRDs
- Status: active → completed/abandoned
- NON-AUTHORITATIVE (never treated as requirements)
- Archived or deleted after PRD creation

**Format expectations**:

- Exploratory and informal
- Questions and hypotheses
- Preliminary findings
- Links to research that may follow

**Boundaries**:

- Does NOT define requirements (see PRDs)
- Does NOT make decisions (see ADRs)
- Does NOT replace formal research (see research/)
- Must transition to PRD to become authoritative

---

#### 7. research/ (Exploratory Research)

**Purpose**: Document spikes, experiments, and benchmarks to inform decisions (NON-AUTHORITATIVE).

**Contains**:

- Technical spikes and experiments
- Performance benchmarks
- Library/tool evaluations
- Proof of concepts
- Investigation findings
- Data to inform ADRs

**When to create**:

- After PRD, before ADRs
- When decisions need data/evidence
- When exploring technical unknowns
- When validating approaches

**Lifecycle**:

- Created as needed to inform decisions
- Status: active → completed
- NON-AUTHORITATIVE (never treated as source of truth)
- Archived after informing ADRs/design docs

**Format expectations**:

- Experimental and data-driven
- Clear methodology
- Findings and conclusions
- Links to ADRs or design docs informed by research

**Boundaries**:

- Does NOT define requirements (see PRDs)
- Does NOT make decisions (see ADRs)
- Does NOT replace initial discovery (see discovery/)
- Findings must be formalized in ADRs/design docs to become authoritative

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
- Reference docs must not include rationale or narrative
- Accepted documents must never be updated without explicit user approval

---

## Structural Rules

- One document = one intent
- Every document MUST include YAML front-matter
- Front-matter format MUST include: `id`, `type`, `status`, `owners`, `applies_to`, `last_updated`, `related`, `structure_notes`
- Front-matter is for agent parsing only; non-agent automation must not parse or depend on it
- Document metadata must live only in YAML front-matter; do not add metadata blocks to the body
- Additional front-matter keys MAY be used when required by a doc type (for example: `decision-date`, `decision-makers` for ADRs).
- `structure_notes` are agent guidance for section order and navigation
- Use stable document IDs
- Prefer explicit links or IDs over prose references
- When referencing other docs in body text, use Markdown links with paths (no bare IDs like `adr-0002`).
- Preserve historical ADRs; deprecate instead of deleting
- Do not collapse multiple documents unless explicitly instructed

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
- Prefer reference → adrs → prds when answering questions
- Prefer precision over completeness
- Prefer explicit uncertainty over assumption
- Enforce documentation workflow dependencies before allowing implementation

This file is authoritative for documentation behavior.
