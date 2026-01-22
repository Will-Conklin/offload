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
- `ios/Offload/Features/` - Feature modules (Capture, Organize)
- `ios/Offload/Domain/Models/` - SwiftData models
- `ios/Offload/Data/Repositories/` - CRUD/query repositories
- `ios/Offload/Data/Persistence/` - SwiftData container setup
- `ios/Offload/DesignSystem/` - Theme, components, icons
- `docs/prds/` - Product requirements
- `docs/adrs/` - Architecture decisions
- `docs/plans/` - Implementation plans

## Common Commands

```bash
open ios/Offload.xcodeproj    # Open in Xcode
# Cmd+B                       # Build
# Cmd+R                       # Run
# Cmd+U                       # Test
```

## Critical Directives

- NEVER commit directly to main branch
- ALWAYS suggest to user a new branch before implementing a new set of changes
- ALWAYS create branches before implementing large features or fixes
- ALWAYS use explicit type references (SwiftData predicates require this for enum cases)
- ALWAYS clean up merged branches
- ALWAYS label pull requests with appropriate labels
- ALWAYS keep documentation up to date
- ALWAYS run markdownlint prior to committing documentation changes, use `--fix` to auto-fix issues
- ALWAYS run yamllint prior to committing yaml changes
- ALWAYS commit atomic commits using conventional commit syntax
- NEVER use markdown files to drive processes or store configuration that scripts parse

## Documentation Authority

All agent behavior related to documentation under `docs/` is governed by `docs/AGENTS.md` (AUTHORITATIVE).

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

- **Primary views**: `CaptureView` (inbox), `OrganizeView` (plans/lists), `CollectionDetailView` (detail), `SettingsView`
- **Design system**: `ios/Offload/DesignSystem/Theme.swift` and `Components.swift`; default theme is `elijah`
- **Data model**: `Item.type == nil` = captures; `Collection.isStructured` distinguishes plans vs lists; `CollectionItem` stores order (`position`) and hierarchy (`parentId`)
- **Relationships**: `Collection.collectionItems` and `Item.collectionItems` use `@Relationship` with cascade delete; `Collection.sortedItems` is canonical ordering
- **Persistence**: Views use `@Query` for reactive data and `@Environment(\.itemRepository)` etc. for mutations
- **Repositories**: Injected via `RepositoryEnvironment.swift`; CRUD in `ios/Offload/Data/Repositories/`
- **Capture flow**: Creates `Item` records (type nil), can attach photo/voice, moves to plan/list via `CollectionItem` link

## Implementation Plans

- Active plans tracked in `docs/plans/`
- Completed plans moved to `docs/plans/_archived/`
