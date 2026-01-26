---
id: reference-frontmatter-schema
type: reference
status: active
owners:
  - Will-Conklin
applies_to:
  - reference
  - documentation
  - agents
last_updated: 2026-01-25
related:
  - docs-agents
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Purpose; Required Fields; Optional Fields; Type-Specific Fields; Field Definitions; Usage Guidelines; Examples."
---
# Frontmatter Schema Reference

Authoritative specification for YAML frontmatter used in all documentation.

## Purpose

Every document in `docs/` MUST include YAML frontmatter for agent parsing. This reference defines all valid fields, their types, and usage rules.

## Required Fields

All documents MUST include:

```yaml
id: string                    # Unique document identifier
type: enum                    # Document type (see types below)
status: enum                  # Lifecycle status (see statuses below)
owners: array[string]         # Individual contributor names
applies_to: array[string]     # Subject tags (see usage below)
last_updated: date            # YYYY-MM-DD format
related: array[string]        # Related document IDs
structure_notes: array[string]# Agent guidance for sections
```

## Optional Fields

MAY be included when applicable:

```yaml
depends_on: array[string]     # Full paths to dependency docs
supersedes: array[string]     # IDs of superseded documents
accepted_by: string|null      # Approver name when accepted
accepted_at: date|null        # Acceptance date YYYY-MM-DD
related_issues: array[string] # GitHub issue numbers or URLs
```

## Type-Specific Fields

### Architecture Decisions (ADRs)

```yaml
decision-date: date           # Date decision was made
decision-makers: array[string]# Names of decision makers
```

## Field Definitions

### `id`

- **Type:** string
- **Format:** `{type}-{number}-{slug}` or `{type}-{slug}`
- **Examples:** `adr-0001-tech-stack`, `prd-0001-product-requirements`, `docs-agents`
- **Rules:**
  - Must be unique across all docs
  - Use kebab-case for slug
  - Numbered sequences (0001, 0002) for ADRs and PRDs
  - Descriptive slugs for all other types

### `type`

- **Type:** enum
- **Valid values:**
  - `architecture-decision` — ADRs
  - `product-requirements` — PRDs
  - `design` — Technical designs
  - `plan` — Implementation plans
  - `research` — Research/spikes
  - `reference` — Contracts, schemas, terminology
  - `discovery` — Early exploration
- **Rules:** Must match directory structure

### `status`

- **Type:** enum
- **Valid values:**
  - `proposed` — Initial draft, not yet accepted
  - `draft` — Work in progress
  - `accepted` — Formally accepted, authoritative
  - `active` — Currently in use (reference docs)
  - `in-progress` — Implementation underway (plans)
  - `completed` — Finished (plans, research)
  - `archived` — No longer active, preserved for history
  - `deprecated` — Superseded, should not be used
  - `superseded` — Replaced by newer document
- **Lifecycle by type:**
  - ADRs: proposed → accepted → (superseded/deprecated)
  - PRDs: proposed → draft → accepted → archived
  - Design: proposed → accepted → archived
  - Plans: proposed → accepted → in-progress → completed/archived
  - Research: active → completed
  - Reference: draft → active → deprecated

### `owners`

- **Type:** array[string]
- **Format:** Individual contributor names
- **Examples:** `[Will-Conklin]`, `[TBD]`
- **Rules:**
  - NEVER use role names (e.g., "design", "product")
  - NEVER use generic names (e.g., "Offload")
  - Use `TBD` if owner unknown
  - Use actual contributor name when known
  - For meta-documentation, use project maintainer name

### `applies_to`

- **Type:** array[string]
- **Purpose:** Subject area/category tags for classification
- **Two distinct patterns:**

#### For Agent Instruction Files (AGENTS.md)

```yaml
applies_to:
  - agents           # REQUIRED for all AGENTS.md files
  - {category}       # Add directory context: adrs, prds, plans, design, etc.
```

**Examples:**

```yaml
# docs/adrs/AGENTS.md
applies_to:
  - agents
  - adrs

# docs/prds/AGENTS.md
applies_to:
  - agents
  - prds
```

#### For Content Documents (ADRs, PRDs, plans, etc.)

```yaml
applies_to:
  - {subject-tags}   # Subject areas, features, or topics
```

**Examples:**

```yaml
# ADR about iOS architecture
applies_to:
  - architecture
  - ios

# PRD for capture feature
applies_to:
  - product
  - capture
  - voice

# Plan for CI work
applies_to:
  - ci
  - automation
```

**Common subject tags:**

- `architecture`, `ios`, `backend`, `data-model`
- `product`, `capture`, `organize`, `navigation`
- `ui`, `ux`, `adhd`, `accessibility`
- `ci`, `testing`, `automation`
- `agents`, `documentation`, `reference`

**Rules:**

- NEVER use owner names here (use `owners` field)
- Use lowercase, kebab-case for multi-word tags
- Choose descriptive, searchable tags
- 1-5 tags per document

### `last_updated`

- **Type:** date
- **Format:** `YYYY-MM-DD`
- **Rules:** Update when content changes materially

### `related`

- **Type:** array[string]
- **Format:** Document IDs only (not paths)
- **Examples:** `[adr-0001, prd-0002-capture]`
- **Rules:** Use for conceptually related documents

### `depends_on`

- **Type:** array[string]
- **Format:** Full file paths from repo root
- **Examples:** `[docs/adrs/adr-0001-tech-stack.md]`
- **Rules:** Use for prerequisite documentation

### `supersedes`

- **Type:** array[string]
- **Format:** Document IDs of superseded docs
- **Examples:** `[adr-0000-old-decision]`
- **Rules:** Mark superseded docs as deprecated/superseded

### `structure_notes`

- **Type:** array[string]
- **Purpose:** Agent guidance for document structure
- **Format:** Free-form strings describing section order
- **Examples:**

  ```yaml
  structure_notes:
    - "Section order: Context; Decision; Consequences; Alternatives; References; Revision History."
    - "Keep top-level sections intact."
  ```

## Usage Guidelines

### Frontmatter Purpose

- **FOR:** Agent parsing and navigation
- **NOT FOR:** Non-agent automation, build scripts, CI tooling
- **RULE:** Only agents may parse frontmatter

### When Creating New Documents

1. Copy template from appropriate README.md
2. Fill required fields completely
3. Set `status: proposed` initially
4. Use `TBD` for owners if unknown
5. Choose appropriate `applies_to` tags
6. Update `last_updated` to creation date

### When Updating Documents

1. Update `last_updated` when content changes
2. Update `status` when lifecycle changes
3. Add to `related` when linking new docs
4. Update `supersedes` if replacing old doc

### Validation Rules

- All required fields MUST be present
- Field values MUST match defined types/enums
- Dates MUST use `YYYY-MM-DD` format
- Arrays MUST be properly formatted YAML
- `applies_to` MUST NOT contain owner names

## Examples

### ADR Frontmatter

```yaml
---
id: adr-0001-technology-stack
type: architecture-decision
status: accepted
owners:
  - Will-Conklin
applies_to:
  - architecture
  - ios
last_updated: 2026-01-25
related:
  - prd-0001-product-requirements
depends_on: []
supersedes: []
accepted_by: Will-Conklin
accepted_at: 2025-12-30
related_issues: []
structure_notes:
  - "Section order: Context; Decision; Consequences; Alternatives Considered; Implementation Notes; References; Revision History."
decision-date: 2025-12-30
decision-makers:
  - Will-Conklin
---
```

### PRD Frontmatter

```yaml
---
id: prd-0001-product-requirements
type: product-requirements
status: accepted
owners:
  - Will-Conklin
applies_to:
  - product
  - capture
  - organize
last_updated: 2026-01-20
related:
  - adr-0001-technology-stack
  - adr-0002-terminology-alignment
depends_on:
  - docs/adrs/adr-0001-technology-stack.md
  - docs/adrs/adr-0002-terminology-alignment.md
supersedes: []
accepted_by: Will-Conklin
accepted_at: 2026-01-03
related_issues:
  - "#123"
structure_notes:
  - "Section order: 1. Product overview; 2. Problem statement; 3. Product goals; 4. Non-goals; 5. Target audience; 6. Success metrics; 7. Core user flows; 8. Functional requirements; 9. Pricing & limits; 10. AI & backend requirements; 11. Data model; 12. UX & tone requirements; 13. Risks & mitigations; 14. Implementation tracking; 15. Open decisions; 16. Revision history."
---
```

### AGENTS.md Frontmatter

```yaml
---
id: adrs-agents
type: reference
status: active
owners:
  - Will-Conklin
applies_to:
  - agents
  - adrs
last_updated: 2026-01-25
related:
  - docs-agents
depends_on: []
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Scope; Purpose; Contains; When to create; Lifecycle; Format expectations; Boundaries."
---
```

### Reference Doc Frontmatter

```yaml
---
id: reference-drag-drop-ordering
type: reference
status: active
owners:
  - Will-Conklin
applies_to:
  - reference
  - organize
  - ui
last_updated: 2026-01-21
related:
  - prd-0004-drag-drop-ordering
  - design-drag-drop-ordering
depends_on:
  - docs/prds/prd-0004-drag-drop-ordering.md
  - docs/design/design-drag-drop-ordering.md
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Definition; Schema; Invariants; Examples."
---
```

## Revision History

- 2026-01-25: Initial schema reference created
