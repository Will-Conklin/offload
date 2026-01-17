<!-- Intent: Summarize the current state of the iOS app, architecture, and outstanding implementation work. -->

# Offload iOS App

SwiftUI iOS application for Offload — a friction-free thought capture and organization tool.

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green.svg)](https://developer.apple.com/xcode/swiftui/)

## Table of Contents

- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Development Status](#development-status)
- [Building & Running](#building--running)
- [Testing](#testing)

## Project Structure

```text
Offload/
├── App/                    # Application entry point & root navigation
├── Features/               # Feature modules organized by screen/flow
│   ├── Capture/          # Capture compose + list
│   └── Organize/          # Organization views (plans and lists, collections, items)
├── Domain/                 # Business logic & models (SwiftData)
│   └── Models/            # Item, Collection, CollectionItem, Tag
├── Data/                   # Data layer
│   ├── Persistence/       # SwiftData configuration via PersistenceController + SwiftDataManager
│   ├── Repositories/      # Data access patterns for items, collections, and tags
│   └── Services/          # VoiceRecordingService for on-device speech recognition
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

```mermaid
graph LR
    subgraph "Presentation Layer"
        VIEW[SwiftUI Views]
    end

    subgraph "Data Layer"
        REPO[Repositories]
        VOICE[VoiceRecordingService]
    end

    subgraph "Persistence Layer"
        DB[(SwiftData)]
    end

    VIEW -->|@Query| DB
    VIEW --> REPO
    VIEW --> VOICE
    REPO --> DB
    VOICE --> DB
```

1. **Domain Layer**: Models defined with SwiftData `@Model` macro
2. **Data Layer**: Repositories provide CRUD operations and queries
3. **Feature Layer**: Views use `@Query` for reactive data or repositories for complex operations

### SwiftData Models

All models use the `@Model` macro for SwiftData persistence:

- **Item**: Core content entity (type: nil/"task"/"link", completedAt timestamp, isStarred, tags array)
- **Collection**: Container for items (isStructured flag determines plan vs list behavior)
- **CollectionItem**: Junction table enabling many-to-many relationships with position and hierarchy
- **Tag**: Simple categorization (name, color)

See [../docs/decisions/ADR-0001-stack.md](../docs/decisions/ADR-0001-stack.md) for detailed architecture decisions.

## Development Status

🚧 **Active Development** — Core data model and UI simplified; capture and organization flows are in place.

### Architecture Implementation

- ✅ Simplified SwiftData models: Item, Collection, CollectionItem, Tag
- ✅ Repository pattern for all models with reactive @Query support
- ✅ Voice recording with real-time transcription
- ✅ Capture view creates Items (type=nil for uncategorized captures)
- ✅ Organization views for Plans (isStructured=true) and Lists (isStructured=false)
- 🔄 Settings view and AI-assisted organization features are future enhancements

### Key Features

- **Offline-First**: All data stored locally with SwiftData
- **Voice Capture**: On-device speech recognition (iOS 17+)
- **Flexible Organization**: Items can belong to multiple collections with position and hierarchy support
- **Unified Model**: Simplified from 13+ entities to 4 core models

## Building & Running

1. Open `Offload.xcodeproj` in Xcode
2. Select a simulator or device
3. Press Cmd+R to build and run

## Testing

### Running Tests

Run tests with ⌘U in Xcode.

### Test Coverage

- Tests use in-memory `ModelContainer` setup for isolation
- Core model tests to be implemented for Item, Collection, CollectionItem, and Tag repositories
- UI tests to be added for capture and organization flows

### Test Framework

Tests currently use **XCTest** (with `@MainActor` where needed) alongside SwiftData in-memory containers.

See main [README](../README.md#running-tests) for detailed testing instructions and outstanding work.
