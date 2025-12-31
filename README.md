# Offload

An iOS app for adults with ADHD to quickly offload thoughts and organize them later, optionally with AI.

## Table of Contents

- [About](#about)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Documentation](#documentation)
- [Tech Stack](#tech-stack)
- [Contributing](#contributing)
- [License](#license)

## About

Offload focuses on externalizing first and organizing later without forcing structure. Thoughts are captured instantly into an Inbox, then optionally organized with AI via a review screen that preserves user control.

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

3. Build and run (Cmd+R)

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
