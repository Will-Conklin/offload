# Offload iOS App

SwiftUI iOS application for Offload.

## Project Structure

```
Offload/
├── App/                    # Application entry point & root navigation
├── Features/               # Feature modules organized by screen/flow
│   ├── Inbox/             # Inbox view & related components
│   ├── Capture/           # Quick capture flow
│   └── Organize/          # Organization views (projects, tags, categories)
├── Domain/                 # Business logic & models (SwiftData)
├── Data/                   # Data layer
│   ├── Persistence/       # SwiftData configuration
│   ├── Networking/        # API client
│   └── Repositories/      # Data access patterns
├── DesignSystem/          # UI components, theme, design tokens
├── Resources/             # Assets, fonts, etc.
└── SupportingFiles/       # Info.plist, entitlements
```

## Architecture

### Feature-Based Organization

The app is organized by feature rather than technical layer:
- Each feature has its own directory under `Features/`
- Features contain views, view models, and feature-specific components
- Shared UI components live in `DesignSystem/`
- Business logic and models live in `Domain/`

### Data Flow

1. **Domain Layer**: Models defined with SwiftData `@Model` macro
2. **Data Layer**: Repositories provide CRUD operations and queries
3. **Feature Layer**: Views use `@Query` for reactive data or repositories for complex operations

## Development Status

This is a scaffolded project with placeholder implementations. Most functionality is marked with `TODO` comments indicating future work needed.

### Implemented
- ✅ Project structure and folder organization
- ✅ SwiftData model definitions (Task, Project, Tag, Category)
- ✅ Basic repository pattern
- ✅ Feature view placeholders (Inbox, Capture, Organize)
- ✅ Design system foundation (Theme, Icons, Components)
- ✅ Main tab navigation

### TODO
- ⬜ Implement full CRUD operations in repositories
- ⬜ Add model relationships (Task ↔ Project, Task ↔ Tags, etc.)
- ⬜ Build out capture flow with all metadata
- ⬜ Implement search and filtering
- ⬜ Add settings and preferences
- ⬜ Implement data sync (CloudKit or custom backend)
- ⬜ Add widgets and app extensions
- ⬜ Complete design system components
- ⬜ Add comprehensive testing

## Building & Running

1. Open `Offload.xcodeproj` in Xcode
2. Select a simulator or device
3. Press Cmd+R to build and run

## Testing

Run tests with Cmd+U in Xcode.

Tests use the Swift Testing framework:
- Define tests with `@Test` attribute
- Use `#expect(...)` for assertions
