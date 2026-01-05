<!-- Intent: Provide an up-to-date overview of Offload, including current implementation status and remaining work. -->

# Offload

An iOS app to quickly capture thoughts and organize them later, optionally with AI assistance.

[![iOS](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green.svg)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg)](LICENSE)
[![iOS Build](https://github.com/Will-Conklin/offload/actions/workflows/ios-build.yml/badge.svg?branch=main)](https://github.com/Will-Conklin/offload/actions/workflows/ios-build.yml)
[![iOS Tests](https://github.com/Will-Conklin/offload/actions/workflows/ios-tests.yml/badge.svg?branch=main)](https://github.com/Will-Conklin/offload/actions/workflows/ios-tests.yml)

## Table of Contents

- [About](#about)
- [Current Status](#current-status)
- [Architecture](#architecture)
- [Data Model](#data-model)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Features](#features)
- [Documentation](#documentation)
- [Tech Stack](#tech-stack)
- [Contributing](#contributing)
- [License](#license)

## About

Offload is an iOS-first app that turns quick thought captures (text or voice) into simple, organized **plans** and lists—tasks, shopping, and follow-ups—so you can get mental space back.

Most productivity tools assume you'll calmly plan everything up front. Offload starts where real life starts: random thoughts, urgency spikes, and "I'll remember" moments. Capture in seconds, then let the app help you sort and clarify what's next—without making everything feel time-sensitive or turning your life into a project management system.

The app follows a simple principle:

**Capture First, Organize Later (Optionally with AI)**

### Core Philosophy

- **Psychological Safety**: No guilt, no shame, no forced structure
- **Offline-First**: Works completely offline, on-device processing
- **User Control**: AI suggests, never auto-modifies
- **Privacy**: All data stays on device, no cloud required

## Current Status

🚧 **Active Development** — Capture and inbox flows are functional; organization and AI flows are still stubbed.

### ✅ Implemented

- SwiftData capture/organization models (CaptureEntry, HandOffRequest/Run, Suggestion, SuggestionDecision, Placement, Plan/Task/Tag/Category, ListEntity/ListItem, CommunicationItem)
- Repository layer plus `CaptureWorkflowService` for capture, inbox queries, and lifecycle operations
- SwiftUI inbox and capture sheet with text + voice recording via `VoiceRecordingService`
- Persistence wired through `PersistenceController` for production and preview containers

### 🔄 In Progress

- AI hand-off orchestration, suggestion processing, and placement (methods stubbed in `CaptureWorkflowService`)
- Organize tab and Settings view (UI exists with TODOs; AppRoot currently routes straight to Inbox instead of the tab shell)
- Consistent capture entry points (MainTabView floating action button vs. direct Inbox navigation)

### 📋 Upcoming

- Present and act on AI suggestions with user approval
- Build destination management flows (plans, categories, tags, lists, communication items) in Organize
- Optional backend sync, widgets, and sharing after validation

## Architecture

### System Overview

```mermaid
graph TB
    subgraph "iOS App (Swift)"
        UI[SwiftUI Views]
        SVC[Service Layer]
        REPO[Repositories]
        DB[(SwiftData)]
        VOICE[VoiceRecordingService]

        UI --> SVC
        SVC --> REPO
        REPO --> DB
        UI --> VOICE
    end

    subgraph "Future: Backend (Optional)"
        API[API Gateway]
        LLM[LLM Proxy]

        SVC -.->|Phase 2+| API
        API -.-> LLM
    end

    style UI fill:#4CAF50
    style SVC fill:#9C27B0
    style DB fill:#2196F3
    style API fill:#FFC107,stroke-dasharray: 5 5
    style LLM fill:#FFC107,stroke-dasharray: 5 5
```

### iOS App Architecture

Feature-based modular architecture with clear separation of concerns:

```mermaid
graph LR
    subgraph "Presentation Layer"
        INBOX[InboxView]
        CAPTURE[CaptureSheetView]
        ORGANIZE[OrganizeView]
    end

    subgraph "Service Layer"
        WORKFLOW[CaptureWorkflowService]
        VOICE[VoiceRecordingService]
    end

    subgraph "Repository Layer"
        CREPO[CaptureRepository]
        HOREPO[HandOffRepository]
        SUGREPO[SuggestionRepository]
        PREPO[PlacementRepository]
        PLANREPO[PlanRepository]
        TREPO[TaskRepository]
    end

    subgraph "Domain Models"
        CAP[CaptureEntry]
        HO[HandOffRequest/Run]
        SUG[Suggestion]
        PLAN[Plan]
        TASK[Task]
    end

    subgraph "Data Layer"
        SWIFTDATA[(SwiftData)]
    end

    INBOX --> WORKFLOW
    CAPTURE --> WORKFLOW
    CAPTURE --> VOICE
    ORGANIZE --> WORKFLOW

    WORKFLOW --> CREPO
    WORKFLOW --> HOREPO
    WORKFLOW --> SUGREPO
    WORKFLOW --> PREPO

    CREPO --> CAP
    HOREPO --> HO
    SUGREPO --> SUG
    PLANREPO --> PLAN
    TREPO --> TASK

    CAP --> SWIFTDATA
    HO --> SWIFTDATA
    SUG --> SWIFTDATA
    PLAN --> SWIFTDATA
    TASK --> SWIFTDATA

    style INBOX fill:#4CAF50
    style CAPTURE fill:#4CAF50
    style ORGANIZE fill:#4CAF50
    style WORKFLOW fill:#9C27B0
    style VOICE fill:#9C27B0
    style SWIFTDATA fill:#2196F3
```

## Data Model

- **Capture + Workflow**: CaptureEntry → HandOffRequest → HandOffRun → Suggestion → SuggestionDecision → Placement
- **Destinations**: Plan/Task, Tag, Category, ListEntity/ListItem, CommunicationItem
- **Lifecycle States**: raw → handedOff → ready → placed → archived

```mermaid
flowchart LR
    Entry[CaptureEntry\n(raw capture)]
    Request[HandOffRequest]
    Run[HandOffRun]
    Suggestion[Suggestion]
    Decision[SuggestionDecision]
    Placement[Placement\n(targetType,targetId)]
    Destination[Plans / Tasks / Lists / Communication]

    Entry --> Request --> Run --> Suggestion --> Decision --> Placement --> Destination
```

### Data Flow: Capture to Inbox

```mermaid
sequenceDiagram
    participant User
    participant CaptureSheet as CaptureSheetView
    participant VoiceService
    participant Workflow as CaptureWorkflowService
    participant SwiftData

    User->>CaptureSheet: Tap microphone
    CaptureSheet->>VoiceService: startRecording()
    VoiceService->>User: Request mic + speech permissions
    VoiceService-->>CaptureSheet: Partial transcription
    CaptureSheet->>User: Show live text

    loop Real-time transcription
        User->>VoiceService: Speak
        VoiceService->>CaptureSheet: Update transcribedText
        CaptureSheet->>User: Display text
    end

    User->>CaptureSheet: Tap save
    CaptureSheet->>Workflow: captureEntry(rawText,inputType,source)
    Workflow->>SwiftData: Insert CaptureEntry
    SwiftData-->>Workflow: Persisted
    Workflow-->>CaptureSheet: Entry saved
    CaptureSheet-->>User: Entry appears in Inbox
```

## Project Structure

This is a monorepo containing:

```text
offload/
├── ios/                          # iOS application
│   ├── Offload/
│   │   ├── App/                  # Application entry point
│   │   ├── Features/             # Feature modules
│   │   │   ├── Capture/          # Voice & text capture
│   │   │   ├── Inbox/            # Thought inbox
│   │   │   └── Organize/         # Task organization
│   │   ├── Domain/               # Business logic
│   │   │   └── Models/           # SwiftData models
│   │   ├── Data/                 # Data layer
│   │   │   ├── Repositories/     # Data access
│   │   │   ├── Persistence/      # SwiftData setup
│   │   │   └── Services/         # Voice, AI services
│   │   ├── DesignSystem/         # UI components, theme
│   │   └── Resources/            # Assets
│   └── OffloadTests/             # Unit tests
├── backend/                      # Backend services (Phase 3+)
├── docs/                         # Documentation
│   ├── prd/                      # Product requirements
│   ├── decisions/                # Architecture Decision Records
│   ├── plans/                    # Implementation plans
│   └── testing/                  # Test guides and results
└── scripts/                      # Build scripts
```

## Getting Started

### Prerequisites

- **Xcode 15.0+** (for iOS 17 support)
- **iOS 17.0+** target device or simulator
- **macOS 14.0+** for development

### Building & Running

1. **Clone the repository**

   ```bash
   git clone https://github.com/Will-Conklin/offload.git
   cd offload
   ```

2. **Open the Xcode project**

   ```bash
   open ios/Offload.xcodeproj
   ```

3. **Select a target**
   - For simulator: Choose any iOS 17+ simulator
   - For device: Connect iPhone and select it

4. **Build and run** (⌘R)

### Running Tests

Run tests with ⌘U in Xcode. Unit tests use in-memory SwiftData containers so they are isolated and fast; ensure test files are included in the `OffloadTests` target after adding new ones.

## Features

### ✅ Implemented

- **Capture**: Text and voice capture with live transcription using the Speech framework (offline-first)
- **Inbox**: Capture inbox with lifecycle tracking (raw → archived) powered by `CaptureWorkflowService`
- **Data Layer**: SwiftData models for capture workflow plus destinations (plans, tasks, tags, categories, lists, communication)
- **Repositories**: CRUD + lifecycle helpers for every model; preview container seeded for SwiftUI previews

### 🚧 In Development

- Manual organization surfaces for plans, tags, and categories (Organize tab contains placeholders)
- AI hand-off orchestration and suggestion processing (workflow methods stubbed)
- Settings, deeper navigation, placement flows, and consistent tab-based shell

### 📅 Planned

- AI-assisted organization with explicit user approval
- Optional backend sync and collaboration features
- Widgets, share extension, and recurrence (based on validation)

## Documentation

### Core Documentation

- 📱 [iOS Development Guide](ios/README.md)
- 📋 [Product Requirements Document](docs/prd/v1.md)
- 🏗️ [Architecture Decision Records](docs/decisions/)
- 🧠 [Thought Capture Model Plan](docs/plans/brain-dump-model.md)
- 📦 [Project Scaffolding Details](ios/SCAFFOLDING.md)

### Testing & Development

- 🎤 [Voice Capture Testing Guide](docs/testing/voice-capture.md)
- 📊 [Voice Capture Test Results](docs/testing/voice-capture-results.md)
- 🧪 SwiftData repositories and workflow tests in `ios/OffloadTests`

### Implementation

- ✅ Thought capture data layer and repositories
- ✅ Inbox and capture experience with voice/text
- 🔄 Organization UI, AI hand-off workflows, and placement flows

## Tech Stack

### iOS Application

- **UI Framework**: SwiftUI 5.0
- **Persistence**: SwiftData (iOS 17+)
- **Speech**: iOS Speech Framework (offline)
- **Audio**: AVFoundation (AVAudioEngine)
- **Architecture**: Feature-based modules, Repository pattern

### Backend (Phase 3+)

- **Language**: Python (FastAPI)
- **AI**: OpenAI/Anthropic API proxy
- **Infrastructure**: TBD

### Development

- **Language**: Swift 5.9
- **Min iOS**: 17.0
- **Testing**: XCTest + SwiftData in-memory containers
- **CI/CD**: GitHub Actions (planned)

See [ADR-0001](docs/decisions/ADR-0001-stack.md) for detailed technical decisions.

## Development Principles

### Friction-Free Design

- **No Forced Structure**: Capture without categorization
- **No Guilt**: No red warnings, no streaks, no shame
- **No Auto-Modification**: AI suggests, user decides
- **Offline-First**: Works without internet

### Privacy & Safety

- **On-Device Processing**: Speech recognition runs locally
- **No Cloud Dependency**: All data stays on device (Phase 1-2)
- **Optional Backend**: Cloud features are opt-in (Phase 3+)
- **No Tracking**: No analytics, no telemetry

### Code Quality

- **Test Coverage**: Comprehensive unit tests (45+ tests)
- **Type Safety**: SwiftData relationships with proper typing
- **Documentation**: Inline docs, ADRs, detailed commit messages
- **Conventional Commits**: Semantic versioning ready

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

## License

See [LICENSE](LICENSE) for details.
