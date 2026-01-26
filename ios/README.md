
# Offload iOS App

SwiftUI iOS application for Offload — a friction-free thought capture and organization tool.

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green.svg)](https://developer.apple.com/xcode/swiftui/)

## Table of Contents

- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Building & Running](#building--running)
- [Testing](#testing)

## Project Structure

```text
Offload/
├── App/                    # Application entry point & root navigation
├── Features/               # Feature modules organized by screen/flow
├── Domain/                 # Business logic & models (SwiftData)
│   └── Models/            # Item, Collection, CollectionItem, Tag
├── Data/                   # Data layer (persistence, repositories, services)
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

See [../docs/adrs/adr-0001-technology-stack-and-architecture.md](../docs/adrs/adr-0001-technology-stack-and-architecture.md) for detailed architecture decisions.

## Building & Running

1. Open `Offload.xcodeproj` in Xcode
2. Select a simulator or device
3. Press Cmd+R to build and run

## Testing

### Running Tests

Run tests with ⌘U in Xcode.

See `docs/design/testing/README.md` for testing guides and checklists.
