# Project: Offload

iOS application built with SwiftUI and SwiftData, targeting iPhone and iPad.

## Architecture

- **Stack**: Swift, SwiftUI, SwiftData
- **Platform**: iOS (iPhone and iPad)
- **Bundle ID**: wc.Offload
- **Pattern**: Feature-based modules with repository pattern for data access
- **Navigation**: `MainTabView` (tabs) → `NavigationStack` (detail) → sheets (edit/pickers)
- **Data**: 4 SwiftData models (Item, Collection, CollectionItem, Tag)

## Key Directories

- `ios/Offload/App/` - App entry point, root navigation
- `ios/Offload/Features/` - Feature modules (Home, Capture, Organize, Settings)
- `ios/Offload/Domain/Models/` - SwiftData models
- `ios/Offload/Data/Repositories/` - CRUD/query repositories
- `ios/Offload/Data/Persistence/` - SwiftData container setup
- `ios/Offload/DesignSystem/` - Theme, components, icons
- `docs/prds/` - Product requirements
- `docs/adrs/` - Architecture decisions
- `docs/plans/` - Implementation plans

## Common Commands

```bash
just                          # List available commands
just xcode-open               # Open in Xcode
just build                    # Build
just test                     # Test
just lint                     # Run markdownlint/yamllint

# Manual Xcode shortcuts
# Cmd+B                       # Build
# Cmd+R                       # Run
# Cmd+U                       # Test
```

## Critical Directives

- NEVER commit directly to main branch
- For feature work: ALWAYS create a new branch (suggest it before starting) and
  never work on main
- For feature work: Use conventional commit prefixes in branch names (examples:
  `feat/`, `fix/`, `docs/`, `chore/`)
- ALWAYS use explicit type references (SwiftData predicates require this for enum cases)
- ALWAYS clean up merged branches
- ALWAYS label pull requests using the repository's label settings; ask the user
  if uncertain
- For feature work: REQUIRE accepted PRD + design + plan + any ADRs before
  implementation; keep docs updated; create reference docs when contracts
  stabilize
- For feature work: Track plans with GitHub issues; update status/comments/links;
  move plan issues through Ready → In Progress → Done using repo project
  settings
- For plan issues: add proposed plans as GitHub issues and add them to the
  Offload project with status Backlog; move to Ready once the plan is accepted;
  move to In Progress when work starts; move to In Review when a PR is open and
  all plan items are complete except User Verification; move to Done after the
  PR merges
- For all new GitHub issues (not only plan issues): always add them to the
  Offload project during creation or immediately after creation
- When creating plans that resolve existing issues: always add an issue comment
  linking the plan document and summarizing approach, phases, and next steps
- NEVER assume version numbers or pricing information; treat them as deferred
  unless explicitly documented
- Pre-commit hygiene: run `markdownlint --fix` for doc changes, `yamllint` for
  YAML, and use conventional atomic commits
- NEVER use markdown files to drive non-agent processes or store configuration
  that non-agent scripts parse; document metadata for agents must live only in
  YAML front-matter per `docs/AGENTS.md`
- Prioritize using `just` for common commands and keep the `justfile` at project root up to date
- For UI work: use `Theme.*` tokens (no hardcoded colors/spacing/radii/fonts)
  and reuse `ios/Offload/DesignSystem/Components.swift` before creating new
  UI primitives

## Documentation Authority

All agent behavior related to documentation under `docs/` is governed by
`docs/AGENTS.md` (AUTHORITATIVE). If this file conflicts with `docs/AGENTS.md`
for documentation behavior, `docs/AGENTS.md` wins.

Agents MUST follow `docs/AGENTS.md` when reading, writing, restructuring, or interpreting documentation. This file governs repository-wide and code-level behavior only.

## Agent-Readable Headers

Add agent-readable headers to non-Markdown config files that agents read/modify:

**YAML/TOML:**

```yaml
# File: docs/index.yaml
# Role: Documentation navigation index
# Authority: Navigation only (not source of truth)
# Governed by: docs/AGENTS.md
# Additional instructions: Additional instructions
```

**JSON:**

```json
{
  "_meta": {
    "role": "reference",
    "authority": "highest",
    "governed_by": "docs/AGENTS.md",
    "additional_instructions": "Additional instructions"
  }
}
```

**ENV/INI/conf/text/other:**

```text
# Purpose: Runtime configuration defaults
# Authority: Config-level
# Governed by: AGENTS.md
# Additional instructions
```

## Agent Handoff Summary

- **Primary views**: `HomeView` (dashboard), `CaptureView` (inbox), `OrganizeView` (plans/lists), `CollectionDetailView` (detail), `SettingsView`
- **Design system**: `ios/Offload/DesignSystem/Theme.swift` and `Components.swift`; theme is `midCenturyModern`
- **Data model**: `Item.type == nil` = captures; `Collection.isStructured` distinguishes plans vs lists; `CollectionItem` stores order (`position`) and hierarchy (`parentId`)
- **Relationships**: `Collection.collectionItems` and `Item.collectionItems` use `@Relationship` with cascade delete; `Collection.sortedItems` is canonical ordering
- **Persistence**: Views use `@Query` for reactive data and `@Environment(\.itemRepository)` etc. for mutations
- **Repositories**: Injected via `RepositoryEnvironment.swift`; CRUD in `ios/Offload/Data/Repositories/`
- **Capture flow**: Creates `Item` records (type nil), can attach photo/voice, moves to plan/list via `CollectionItem` link
