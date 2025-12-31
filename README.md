# Offload

A productivity app for capturing and processing thoughts on iOS.

## Overview

Offload helps you quickly capture thoughts, ideas, and tasks as they occur, then organize them later. Built with SwiftUI and SwiftData for a native iOS experience.

## Project Structure

This is a monorepo containing:

- **ios/** - iOS application
- **backend/** - Backend services (planned)
- **docs/** - Documentation and architecture decisions
- **scripts/** - Build and deployment scripts

## Getting Started

### Prerequisites

- Xcode 15.0 or later
- iOS 17.0+ target device or simulator
- macOS 14.0+ for development

### Building & Running

1. Open the Xcode project:
   ```bash
   open ios/Offload.xcodeproj
   ```

2. Select a simulator or device

3. Build and run (⌘R)

## Features

### Current
- ✅ Quick thought capture
- ✅ Inbox view with chronological list
- ✅ SwiftData persistence
- ✅ Text-based input

### Planned
- ⬜ Voice capture
- ⬜ Thought processing and organization
- ⬜ Projects and tags
- ⬜ Search and filtering
- ⬜ Cloud sync
- ⬜ Widgets

## Documentation

- [iOS Development Guide](ios/README.md)
- [Product Requirements](docs/prd/v1.md)
- [Architecture Decisions](docs/decisions/)
- [Project Scaffolding](ios/SCAFFOLDING.md)

## Tech Stack

- **iOS**: SwiftUI, SwiftData
- **Architecture**: Feature-based modules, repository pattern
- **Backend**: TBD (planned)

See [ADR-0001](docs/decisions/ADR-0001-stack.md) for detailed technical decisions.

## Contributing

This is currently a personal project. Contributions guidelines to be added.

## License

See [LICENSE](LICENSE) for details.
