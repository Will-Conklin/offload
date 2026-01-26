<!--
Intent: Provide a high-level overview of Offload and point to authoritative docs.
-->

# Offload

An iOS app to quickly capture thoughts and organize them later, optionally with
AI assistance.

[![iOS][badge-ios]][link-ios]
[![Swift][badge-swift]][link-swift]
[![SwiftUI][badge-swiftui]][link-swiftui]
[![License][badge-license]][link-license]
[![iOS Build][b-ios-build]][l-ios-build]
[![iOS Tests][b-ios-tests]][l-ios-tests]
[![Coverage][b-ios-coverage]][l-ios-coverage]

[badge-ios]: https://img.shields.io/badge/iOS-17.0+-blue.svg
[link-ios]: https://www.apple.com/ios/
[badge-swift]: https://img.shields.io/badge/Swift-5.9-orange.svg
[link-swift]: https://swift.org
[badge-swiftui]: https://img.shields.io/badge/SwiftUI-5.0-green.svg
[link-swiftui]: https://developer.apple.com/xcode/swiftui/
[badge-license]: https://img.shields.io/badge/license-MIT-lightgrey.svg
[link-license]: LICENSE
[b-ios-build]: https://github.com/Will-Conklin/offload/actions/workflows/ios-build.yml/badge.svg
[l-ios-build]: https://github.com/Will-Conklin/offload/actions/workflows/ios-build.yml
[b-ios-tests]: https://github.com/Will-Conklin/offload/actions/workflows/ios-tests.yml/badge.svg
[l-ios-tests]: https://github.com/Will-Conklin/offload/actions/workflows/ios-tests.yml
[b-ios-coverage]: https://img.shields.io/github/actions/workflow/status/Will-Conklin/offload/ios-tests.yml?branch=main&label=coverage&logo=githubactions
[l-ios-coverage]: https://github.com/Will-Conklin/offload/actions/workflows/ios-tests.yml

## Table of Contents

- [About](#about)
- [Principles](#principles)
- [Status](#status)
- [Documentation](#documentation)
- [Getting Started](#getting-started)
- [Contributing](#contributing)
- [License](#license)

## About

Offload helps people capture thoughts quickly and organize them later into
simple plans and lists. It is built around a capture-first flow that favors
low friction and clarity over heavy structure.

## Principles

- Psychological safety (no guilt or pressure)
- Offline-first by default
- User control over any AI assistance
- Privacy-conscious by design

## Status

Active development. For current plans and milestones, see
`docs/plans/README.md`.

## Documentation

- [Documentation index](docs/index.yaml) — navigation map for all docs.
- [Product requirements](docs/prds/README.md) — scope, goals, and success criteria.
- [Architecture decisions](docs/adrs/README.md) — ADR index and rationale.
- [Design docs](docs/design/README.md) — technical approach and test guidance.
- [Implementation plans](docs/plans/README.md) — execution sequencing and status.
- [Reference docs](docs/reference/README.md) — contracts, schemas, and invariants.
- [Research](docs/research/README.md) — exploratory notes and reviews.
- [iOS Development Guide](ios/README.md) — setup, build, and run details.

## Getting Started

Open the Xcode project and run the app:

```bash
open ios/Offload.xcodeproj
```

See `ios/README.md` for setup details.

## Contributing

See `CONTRIBUTING.md` for contribution guidelines.

## License

See `LICENSE` for details.
