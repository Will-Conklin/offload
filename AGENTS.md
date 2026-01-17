# offload

iOS application built with SwiftUI and SwiftData, targeting iPhone and iPad.

## Critical

- ALWAYS add headers to key files for agent navigation. Use the AGENT NAV format:

  ```swift
  // AGENT NAV
  // - Section Name
  // - Another Section
  ```

- ALWAYS create branches before implementing new features or fixes. Consider worktrees for more complex work or refactors.
- ALWAYS use explicit type references. SwiftData predicates require explicit type references for enum cases
- ALWAYS clean up merged branches.
- ALWAYS label pull requests with appropriate labels (bug, enhancement, documentation, etc.).
- ALWAYS keep documentation up to date.
- ALWAYS run markdownlint prior to committing documentation changes (no need to rerun after every edit).
- DO NOT make README a changelog.  While in development, PR history can be used to track changes, release notes will be used after initial v1 release.
- NEVER use markdown files to drive processes or store configuration that scripts parse. Use appropriate config formats (JSON, YAML, env files, shell scripts with hardcoded values) instead. Markdown is for human-readable documentation only.
- ALWAYS use conventional commit syntax

## Product Philosophy

**Offload** helps people capture thoughts and organize them with minimal friction.

### Primary App Goals

- Minimize friction in capture and organization
- Reduce cognitive load throughout the experience
- Convert raw thoughts into structured lists and plans

### App Non-Goals

- Complex project management features
- Time-driven task pressure or urgency
- Over-verbose UI or AI output

### App AI Behavior Guidelines

- Assist, do not judge user's choices or input
- Suggest structure, do not enforce it
- Prefer fewer options over many (reduce decision fatigue)
- Keep suggestions concise and actionable

### Design Principles

- When unsure about a design decision, ask for clarification
- Default to simpler designs over complex ones
- Prioritize speed of capture over completeness
- Let users organize later rather than forcing structure upfront

## Agent Handoff Summary

- **App intent**: Capture-first workflow; captures are uncategorized items and organization happens later in Plans (structured) and Lists (unstructured).
- **Primary views**: `CaptureView` (inbox), `OrganizeView` (plans/lists), `CollectionDetailView` (plan/list detail), `SettingsView`.
- **Navigation**: Root `MainTabView` for top-level tabs; `NavigationStack` for detail navigation; sheets use `sheet(item:)` for edit/pickers.
- **Design system**: Single source of truth in `ios/Offload/DesignSystem/Theme.swift` and `ios/Offload/DesignSystem/Components.swift`; icons centralized in `ios/Offload/DesignSystem/Icons.swift` and `ios/Offload/DesignSystem/AppIcon.swift`; default theme is `elijah`.
- **Data model**: Four SwiftData models only (Item, Collection, CollectionItem, Tag). `Item.type == nil` represents captures; `Collection.isStructured` distinguishes plans vs lists; `CollectionItem` stores order (`position`) and hierarchy (`parentId`).
- **Relationships**: `Collection.collectionItems` and `Item.collectionItems` are `@Relationship` with cascade delete; `Collection.sortedItems` is the canonical ordering used by detail views.
- **Persistence**: `PersistenceController` and `SwiftDataManager` register the schema; views access context via `@Environment(\.modelContext)` and use `@Query` or `FetchDescriptor`.
- **Repositories**: CRUD lives in `ios/Offload/Data/Repositories/` for Item, Collection, CollectionItem, Tag; prefer using these for queries/mutations.
- **Capture flow**: Capture UI creates `Item` records (type nil), can attach photo/voice, and moves to plan/list by creating a `CollectionItem` link.

## UI Design Component Principles

- Common as possible, unique as necessary

## Implementation Plans

- ALWAYS keep plans up to date
- Active implementation plans are tracked in [docs/sdlc/plans/](docs/sdlc/plans/)
- Move completed plans to [docs/sdlc/plans/_archived/](docs/sdlc/plans/_archived/)

## Project

- **Type**: Monorepo (iOS app + backend)
- **iOS Language**: Swift
- **UI Framework**: SwiftUI
- **Data**: SwiftData (persistent storage)
- **Bundle ID**: wc.offload
- **Platform**: iOS (iPhone and iPad)

## Structure

```text
offload/
  README.md
  LICENSE
  .gitignore
  AGENTS.md

  ios/                           # iOS application
    Offload.xcodeproj           # Xcode project
    Offload/
      App/                      # App entry point, configuration
        offloadApp.swift        # App entry + modelContainer injection
        AppRootView.swift       # Root navigation
        MainTabView.swift       # Tab shell (inbox/organize/settings)
      Features/                 # Feature modules
        Capture/                # Capture compose + list
        Organize/OrganizeView.swift
      Domain/                   # Business logic, models
        Models/                 # SwiftData models (4 models)
      Data/                     # Data layer
        Persistence/            # SwiftData container setup
        Repositories/           # CRUD/query repositories
        Services/               # Service layer (voice recording, etc.)
        Networking/             # API client
      DesignSystem/             # UI components, theme
      Resources/                # Assets, fonts
        Assets.xcassets/
      SupportingFiles/          # Info.plist, etc.
    OffloadTests/               # Unit tests
    OffloadUITests/             # UI tests

  backend/                      # Backend services
    README.md
    api/
      src/                      # API source code
      tests/                    # API tests
    infra/                      # Infrastructure as code

  docs/                         # Documentation
    plans/                      # Implementation plans
    testing/                    # Test documentation and results
    prd/                        # Product requirements
    architecture/               # Architecture docs
    decisions/                  # ADRs (Architecture Decision Records)

  scripts/                      # Build/deploy scripts
    ios/                        # iOS scripts
    backend/                    # Backend scripts
```

## Commands

### iOS - Build & Run

```bash
# Open in Xcode (required for building/running)
open ios/Offload.xcodeproj

# Build: Cmd+B in Xcode
# Run: Cmd+R in Xcode
# Test: Cmd+U in Xcode
```

Note: xcodebuild CLI requires full Xcode, not Command Line Tools.

### iOS - Testing

- Uses Swift Testing framework (not XCTest)
- Define tests with `@Test` attribute
- Assertions use `#expect(...)`

### Backend

TBD - Backend implementation coming soon.

## Architecture

See **Agent Handoff Summary** above for model overview, views, and data flow.

### iOS - SwiftData Setup

1. **ModelContainer** created in `Data/Persistence/PersistenceController.swift`
2. **Container injection** happens in `App/offloadApp.swift`
3. **Models** defined with `@Model` macro in `Domain/Models/`
4. **Storage** configured as persistent (not in-memory) in `PersistenceController.shared`
5. **Context** accessed via `@Environment(\.modelContext)` in views
6. **Queries** use `@Query` property wrapper for reactive data

### iOS - Adding New Models

1. Create model with `@Model` macro in `Domain/Models/`
2. Register in schema: `Data/Persistence/PersistenceController.swift`
3. Update `Data/Persistence/SwiftDataManager.swift` schema
4. Query in views with `@Query`

### iOS - SwiftUI Patterns

- **Navigation**: `NavigationStack` + `TabView` for top-level flows
- **Model Context**: Use `modelContext.insert()` / `.delete()`
- **Animations**: Wrap SwiftData mutations in `withAnimation`
