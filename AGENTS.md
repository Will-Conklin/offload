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
        offloadApp.swift        # ModelContainer setup
      Features/                 # Feature modules
        ContentView.swift       # Main view (NavigationSplitView)
      Domain/                   # Business logic, models
        Item.swift              # SwiftData models
      Data/                     # Data layer, repositories
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

1. **ModelContainer** created in `App/offloadApp.swift` with schema registration
2. **Models** defined with `@Model` macro in `Domain/`
3. **Storage** configured as persistent (not in-memory)
4. **Context** accessed via `@Environment(\.modelContext)` in views
5. **Queries** use `@Query` property wrapper for reactive data

### iOS - Adding New Models

1. Create model with `@Model` macro in `Domain/`
2. Register in schema: `App/offloadApp.swift` (ModelContainer setup)
3. Query in views with `@Query`

### iOS - SwiftUI Patterns

- **Navigation**: `NavigationSplitView` for master-detail
- **Model Context**: Use `modelContext.insert()` / `.delete()`
- **Animations**: Wrap SwiftData mutations in `withAnimation`
