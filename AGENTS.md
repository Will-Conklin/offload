# offload

iOS application built with SwiftUI and SwiftData, targeting iPhone and iPad.

## Product Philosophy

**Offload** helps people capture thoughts and organize them with minimal friction.

### Primary Goals

- Minimize friction in capture and organization
- Reduce cognitive load throughout the experience
- Convert raw thoughts into structured lists and plans

### Non-Goals

- Complex project management features
- Time-driven task pressure or urgency
- Over-verbose UI or AI output

### AI Behavior Guidelines

- Assist, do not judge user's choices or input
- Suggest structure, do not enforce it
- Prefer fewer options over many (reduce decision fatigue)
- Keep suggestions concise and actionable

### Design Principles

- When unsure about a design decision, ask for clarification
- Default to simpler designs over complex ones
- Prioritize speed of capture over completeness
- Let users organize later rather than forcing structure upfront

## Critical

- ALWAYS add intent header to key files.
- ALWAYS create branches before implementing new features or fixes. Consider worktrees for more complex work or refactors.
- ALWAYS clean up merged branches.
- ALWAYS label pull requests with appropriate labels (bug, enhancement, documentation, etc.).
- ALWAYS keep documentation up to date.
- ALWAYS run markdownlint prior to committing documentation.
- DO NOT make README a changelog.  While in development, PR history can be used to track changes, release notes will be used after initial v1 release.

## Implementation Plans

Active implementation plans are tracked in [docs/plans/](docs/plans/):

- [Thought Capture Model](docs/plans/brain-dump-model.md) - Event-sourced architecture for capture and AI-assisted organization

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
        Inbox/InboxView.swift   # Inbox list
        Capture/                # Capture flows (sheet + full screen)
        Organize/OrganizeView.swift
        ContentView.swift       # Legacy scaffold view
      Domain/                   # Business logic, models
        Models/                 # SwiftData models (13 models - event-sourced capture workflow)
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

### iOS - Feature-Based Organization

Code is organized by feature and layer:

- **App/**: App lifecycle, configuration, dependency injection
- **Features/**: UI screens and flows grouped by feature (Inbox, Capture, Organize)
- **Domain/**: Business logic, models (event-sourced capture architecture)
- **Data/**: Persistence, repositories, services, networking
- **DesignSystem/**: Reusable UI components, themes, design tokens

### iOS - Current Model Implementation

Event-sourced capture architecture with 13 SwiftData models:

**Workflow Models**: CaptureEntry, HandOffRequest, HandOffRun, Suggestion, SuggestionDecision, Placement

**Destination Models**: Plan, Task, Tag, Category, ListEntity, ListItem, CommunicationItem

See [Thought Capture Model Plan](docs/plans/brain-dump-model.md) for architecture details.

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
