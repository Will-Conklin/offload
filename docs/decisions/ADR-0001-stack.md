# ADR-0001: Technology Stack and Architecture

**Status:** Accepted
**Date:** 2025-12-30
**Deciders:** Will Conklin
**Tags:** architecture, ios, backend

## Context

We need to choose a technology stack for Offload that enables:
- Rapid development and iteration
- Native iOS performance and feel
- Reliable local data persistence
- Future scalability for cloud sync
- Modern development practices

## Decision

We will use the following technology stack:

### iOS Application

**Framework:** SwiftUI
- **Rationale:** Modern declarative UI, less boilerplate than UIKit
- **Benefits:** Automatic updates via @Query, built-in animations, preview support
- **Trade-offs:** iOS 17+ required, some edge cases need UIKit

**Data Persistence:** SwiftData
- **Rationale:** Native Apple framework, seamless SwiftUI integration
- **Benefits:** Type-safe models, automatic migration, CloudKit sync ready
- **Trade-offs:** iOS 17+ required, less mature than Core Data

**Architecture Pattern:** Feature-based modules with repository pattern
- **Rationale:** Scales well as app grows, clear separation of concerns
- **Structure:**
  ```
  - App/ (entry point, navigation)
  - Features/ (UI organized by feature)
  - Domain/ (business logic, models)
  - Data/ (persistence, networking, repositories)
  - DesignSystem/ (reusable UI components)
  ```

**State Management:** SwiftUI @Query and @Environment
- **Rationale:** Built-in, works seamlessly with SwiftData
- **Benefits:** Automatic UI updates, minimal boilerplate
- **Trade-offs:** Less control than custom solutions

### Backend (Planned)

**Decision Deferred:** Backend technology to be determined when needed
- **Considerations:** May not need backend for v1.0 (local-only)
- **Future Options:** Vapor (Swift), Node.js, or managed services
- **Requirements:** Must support CloudKit or custom sync protocol

### Development Tools

**IDE:** Xcode
- Required for iOS development

**Version Control:** Git with GitHub
- Standard choice, good CI/CD integration

**Testing:** Swift Testing framework
- Modern alternative to XCTest, cleaner syntax

## Consequences

### Positive

1. **Native Performance:** SwiftUI + SwiftData provide excellent performance
2. **Productivity:** Declarative UI and automatic updates reduce boilerplate
3. **Future-Ready:** SwiftData designed for CloudKit sync
4. **Type Safety:** Swift's strong typing catches errors at compile time
5. **Maintainability:** Clear architecture makes codebase easy to navigate

### Negative

1. **iOS 17+ Only:** Limits potential user base (acceptable for new app)
2. **SwiftData Maturity:** Fewer resources than Core Data
3. **Learning Curve:** Team must learn SwiftData specifics
4. **Migration Cost:** Moving away from SwiftData would be expensive

### Neutral

1. **Monorepo Structure:** Keeps iOS and backend together, may split later
2. **Repository Pattern:** Adds abstraction layer, beneficial as app grows

## Alternatives Considered

### UIKit + Core Data
- **Pros:** Mature, larger ecosystem, broader iOS support
- **Cons:** More boilerplate, slower development
- **Decision:** Rejected - SwiftUI benefits outweigh iOS version constraint

### Realm
- **Pros:** Cross-platform, good performance, established
- **Cons:** Third-party dependency, migration to SwiftData harder
- **Decision:** Rejected - prefer Apple frameworks for longevity

### MVVM without Repository Pattern
- **Pros:** Simpler, less code
- **Cons:** ViewModels become bloated as app grows
- **Decision:** Rejected - repository pattern adds useful abstraction

### Redux/TCA for State Management
- **Pros:** Predictable state, good for complex apps
- **Cons:** Significant boilerplate, overkill for v1.0
- **Decision:** Rejected - @Query sufficient for current needs, can add later

## Implementation Notes

### SwiftData Setup
- Use `PersistenceController` for app-wide container
- Separate `preview` container for SwiftUI previews with sample data
- Keep `SwiftDataManager` for complex multi-model scenarios

### Feature Organization
- Each feature gets its own directory
- Related views, view models, and components stay together
- Shared components go in DesignSystem

### Repository Pattern
- Repositories provide clean interface to data layer
- Allow swapping persistence mechanisms if needed
- Keep ViewModels focused on presentation logic

## References

- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [SwiftUI Best Practices](https://developer.apple.com/documentation/swiftui)
- [iOS App Architecture](https://www.objc.io/books/app-architecture/)
- [Repository Pattern](https://martinfowler.com/eaaCatalog/repository.html)

## Revision History

- 2025-12-30: Initial decision (v1.0)
