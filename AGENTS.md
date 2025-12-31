# offload

iOS application built with SwiftUI and SwiftData, targeting iPhone and iPad.

## Project

- **Type**: Monorepo (iOS app + backend)
- **iOS Language**: Swift
- **UI Framework**: SwiftUI
- **Data**: SwiftData (persistent storage)
- **Bundle ID**: wc.offload
- **Platform**: iOS (iPhone and iPad)

## Structure

```
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
        Models/                 # SwiftData models
      Data/                     # Data layer, repositories
        Persistence/            # SwiftData container setup
        Repositories/           # CRUD/query repositories
        Networking/APIClient.swift
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
- **Features/**: UI screens and flows grouped by feature
- **Domain/**: Business logic, models, use cases (framework-independent)
- **Data/**: Repositories, data sources, API clients
- **DesignSystem/**: Reusable UI components, themes, design tokens

### iOS - SwiftData Setup

1. **ModelContainer** created in `Data/Persistence/PersistenceController.swift`
2. **Container injection** happens in `App/offloadApp.swift`
3. **Models** defined with `@Model` macro in `Domain/`
4. **Storage** configured as persistent (not in-memory) in `PersistenceController.shared`
5. **Context** accessed via `@Environment(\.modelContext)` in views
6. **Queries** use `@Query` property wrapper for reactive data

### iOS - Adding New Models

1. Create model with `@Model` macro in `Domain/`
2. Register in schema: `Data/Persistence/PersistenceController.swift`
3. If using the full schema container, also update `Data/Persistence/SwiftDataManager.swift`
4. Query in views with `@Query`

### iOS - SwiftUI Patterns

- **Navigation**: `NavigationStack` + `TabView` for top-level flows
- **Model Context**: Use `modelContext.insert()` / `.delete()`
- **Animations**: Wrap SwiftData mutations in `withAnimation`
