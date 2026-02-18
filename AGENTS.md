# Project: Offload

iOS application with a FastAPI backend slice.

## Architecture

- **Stack**: Swift, SwiftUI, SwiftData, Python, FastAPI
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
- `backend/api/` - FastAPI backend package
- `scripts/ci/` - CI lane scripts (iOS/backend/scripts)
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
just ios-test-ci              # Run iOS CI-style test lane locally
just backend-install-uv       # Sync backend dev dependencies with uv
just backend-check            # Run backend ruff + ty + pytest
just backend-test-coverage    # Run backend tests with coverage summary
just backend-check-coverage   # Run backend lint + typecheck + coverage tests
just backend-clean            # Remove generated backend runtime/build artifacts
just backend-check-ci         # Run backend CI script locally
just ci-local                 # Run lint + backend checks + iOS tests

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
- For feature work: follow a TDD cycle (red → green → refactor): write tests
  first, implement the minimal code to pass, then refactor with tests green
- For plan generation in Plan mode: encode TDD steps in each implementation
  phase/slice (red tests, green implementation, refactor)
- For feature work: Track plans with GitHub issues; update status/comments/links;
  move plan issues through Ready → In Progress → Done using repo project
  settings
- For plan issues: add proposed plans as GitHub issues and add them to the
  Offload project with status Backlog; move to Ready once the plan is accepted;
  move to In Progress when work starts; move to In Review when a PR is open and
  all plan items are complete except User Verification; move to Done after the
  PR merges
- If an implementation PR merges while plan User Verification tasks remain:
  open a new GitHub issue labeled `uat`, add it to the Offload project with
  status `Ready`, and link the plan + merged PR; keep the plan `uat` until
  verification is complete
- For all new GitHub issues (not only plan issues): always add them to the
  Offload project during creation or immediately after creation
- For all new GitHub issues: apply labels at creation time and never leave an
  issue unlabeled
- For GitHub issue/PR descriptions created via `gh`: use `--body-file` (or a
  heredoc with real line breaks) and never pass escaped `\n` sequences as body
  text
- Use `bug` for defects/regressions, `enhancement` for feature or implementation
  work, and `documentation` for docs-only work
- Use `uat` only for post-merge user verification follow-up issues
- Any issue labeled `uat` must be placed in project status `Ready` (not
  `Backlog`)
- Use `ux` as an additional label (with the primary label above) when the issue
  is primarily about UX/UI behavior
- If label selection is ambiguous, ask the user before creating or relabeling
  issues
- After creating/updating issues, PRs, or project statuses, run a sync audit and
  fix mismatches before finishing:
  - every open issue is in the Offload project
  - no open issue is unlabeled
  - open issues are not in `Done`/`Archived`
  - closed issues are in `Done`/`Archived`
  - `In review` is used only when a relevant PR is currently open
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
- For backend changes: run `just backend-check` (or `just backend-check-ci`) before opening/updating PRs
- For backend persistence, security, or provider-resilience changes: run
  `just backend-check-coverage` before opening/updating PRs
- Never commit generated backend runtime/build artifacts (`.offload-backend/`,
  `backend/api/.offload-backend/`, `backend/api/src/offload_backend_api.egg-info/`);
  use `just backend-clean` when needed
- For UI work: use `Theme.*` tokens (no hardcoded colors/spacing/radii/fonts)
  and reuse `ios/Offload/DesignSystem/Components.swift` before creating new
  UI primitives
- For new or modified production functions/methods: add concise doc comments
  documenting purpose, key parameters, and return behavior when not `Void`

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
