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
│   ├── Inbox/             # Inbox view & related components (uses CaptureWorkflowService)
│   ├── Capture/           # Quick capture flow (text + voice)
│   └── Organize/          # Organization views (plans, tags, categories; TODO actions)
├── Domain/                 # Business logic & models (SwiftData)
│   └── Models/            # CaptureEntry, HandOff*, Suggestion*, Placement, Plan/Task/Tag/Category/List/Communication
├── Data/                   # Data layer
│   ├── Persistence/       # SwiftData configuration via PersistenceController + SwiftDataManager
│   ├── Repositories/      # Data access patterns for capture, hand-off, suggestions, placements, and destinations
│   └── Services/          # VoiceRecordingService, CaptureWorkflowService stubs for AI orchestration
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

All models use the `@Model` macro with enum raw-value storage for SwiftData compatibility:

- **Capture workflow**: CaptureEntry → HandOffRequest/Run → Suggestion → SuggestionDecision → Placement
- **Destinations**: Plan, Task, Tag, Category, ListEntity/ListItem, CommunicationItem

See [../docs/decisions/ADR-0001-stack.md](../docs/decisions/ADR-0001-stack.md) for detailed architecture decisions.

## Development Status

🚧 **Active Development** — Capture and inbox flows are in place; AI hand-off and most organization UI are still TODO.

### Architecture Implementation

- ✅ SwiftData models for capture workflow and destination entities
- ✅ Repository pattern for all models plus `CaptureWorkflowService` for inbox/capture orchestration
- ✅ Voice recording with real-time transcription in `CaptureSheetView`
- 🔄 Organize tab, Settings view, and AI submission/placement flows remain stubbed

### Key Features

- **Offline-First**: All data stored locally with SwiftData
- **Voice Capture**: On-device speech recognition (iOS 17+)
- **Lifecycle Helpers**: Repositories wrap state transitions for captures, suggestions, and placements
- **Testing**: In-memory SwiftData containers exercised through XCTest

## Building & Running

1. Open `Offload.xcodeproj` in Xcode
2. Select a simulator or device
3. Press Cmd+R to build and run

## Testing

### Running Tests

Run tests with ⌘U in Xcode.

### Test Coverage

- Repository tests for capture, hand-off, suggestions, placements, plans, tasks, tags, categories, lists, and communication items
- Workflow tests for capture + inbox behaviors (AI submission/placement tests not yet written)
- In-memory `ModelContainer` setup in each test case for isolation

### Test Framework

Tests currently use **XCTest** (with `@MainActor` where needed) alongside SwiftData in-memory containers.

See main [README](../README.md#running-tests) for detailed testing instructions and outstanding work.
