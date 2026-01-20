---
id: adr-0001-technology-stack-and-architecture
type: architecture-decision
status: accepted
owners:
  - will-conklin
applies_to:
  - architecture
  - ios
  - backend
last_updated: 2025-12-31
related: []
structure_notes:
  - "Section order: Context; Decision; Consequences; Alternatives Considered; Implementation Notes; References; Revision History."
  - "Keep the top-level section outline intact."
decision-date: 2025-12-30
decision-makers:
  - will-conklin
---

<!-- Intent: Record the chosen technology stack and keep implementation notes aligned with the current codebase. -->

# adr-0001: Technology Stack and Architecture

**Status:** Accepted
**Decision Date:** 2025-12-30
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

  ```text
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

- **Considerations:** May not need backend for v1 (local-only)
- **Future Options:** Vapor (Swift), Node.js, or managed services
- **Requirements:** Must support CloudKit or custom sync protocol

### Development Tools

**IDE:** Xcode

- Required for iOS development

**Version Control:** Git with GitHub

- Standard choice, good CI/CD integration

**Testing:** XCTest with SwiftData in-memory containers (Swift Testing can be revisited later)

- Current codebase uses XCTest; Swift Testing remains an option once tooling stabilizes

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
- **Cons:** Significant boilerplate, overkill for v1
- **Decision:** Rejected - @Query sufficient for current needs, can add later

## Implementation Notes

### SwiftData Setup

- Use `PersistenceController` for the app-wide container.
- Separate `preview` container for SwiftUI previews with sample data.
- Keep `SwiftDataManager` for configurable containers (CloudKit, migrations, backup/restore TODOs).
- Schema registers core models (`Item`, `Collection`, `CollectionItem`, `Tag`).

### SwiftData Relationships

- **@Relationship** annotations with delete rules tuned per entity:
  - Cascade: Collection → CollectionItem; Item → CollectionItem
  - CollectionItem links Item ↔ Collection for many-to-many membership
- Tag is a standalone model; item tag values are stored on `Item.tags`.
- Enum properties stored as strings with computed wrappers for type safety.

### Feature Organization

- Each feature gets its own directory
- Related views, view models, and components stay together
- Shared components go in DesignSystem

### Repository Pattern (Current)

- Repositories wrap SwiftData operations for core entities (Item, Collection, CollectionItem, Tag).
- Views use `@Query` or repositories depending on complexity.
- Pattern keeps views lightweight and enables future persistence swaps if needed.

### SwiftData Predicate Limitations (Week 2 Findings)

- **Enum comparisons not supported**: Cannot use `#Predicate { $0.status == .inbox }`
  - Workaround: Fetch all and filter in memory
- **lowercased() not supported**: String case transformation not available in predicates
  - Workaround: Use case-sensitive search
- **Limited optional chaining**: Complex optional predicates not supported
  - Workaround: Fetch all and filter in memory for complex queries
- Acceptable for MVP scale, can optimize later with custom indexing if needed

## References

- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [SwiftUI Best Practices](https://developer.apple.com/documentation/swiftui)
- [iOS App Architecture](https://www.objc.io/books/app-architecture/)
- [Repository Pattern](https://martinfowler.com/eaaCatalog/repository.html)

## Revision History

- 2025-12-30: Initial decision (v1)
- 2025-12-31: Updated with Week 2 implementation findings (SwiftData relationships, repository queries, predicate limitations)
