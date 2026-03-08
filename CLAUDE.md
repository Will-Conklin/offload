# Project: Offload

iOS app built with SwiftUI and SwiftData (iPhone + iPad).

## Quick Reference

- **Bundle ID**: wc.Offload
- **Pattern**: Feature-based modules with repository pattern
- **Navigation**: `MainTabView` → `NavigationStack` → sheets
- **Models**: Item, Collection, CollectionItem, Tag (SwiftData)
- **Design system**: `DesignSystem/Theme.swift`, theme `midCenturyModern`

## Quick Start

```bash
# First time setup
git clone <repo>
cd offload
just build          # Builds for iOS Simulator
just test           # Runs all tests
just xcode-open     # Opens in Xcode for development
```

## Backend Environment Variables

Required for production-like environments:

- `OFFLOAD_ENVIRONMENT` — Environment name (dev/test/production)
- `OFFLOAD_SESSION_SECRET` — Session signing secret (required in production)
- `OFFLOAD_SESSION_TOKEN_ISSUER` — Token issuer (default: offload-backend)
- `OFFLOAD_SESSION_TOKEN_AUDIENCE` — Token audience (default: offload-ios)
- `OFFLOAD_SESSION_TOKEN_ACTIVE_KID` — Active key ID (default: v2-default)
- `OFFLOAD_SESSION_SIGNING_KEYS` — Optional JSON map for key rotation (e.g., `{"v2-default":"<secret>"}`)
- `OFFLOAD_USAGE_DB_PATH` — Path to usage tracking database

Development/test: If `OFFLOAD_SESSION_SECRET` is unset, a random in-memory secret is generated at startup.

## Commands

```bash
just                    # List all commands
just build              # Build (Debug, iOS Simulator)
just test               # Run tests; for direct run: xcodebuild test -project ios/Offload.xcodeproj -scheme Offload -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2'
just lint               # Run markdownlint + yamllint
just lint-docs          # Markdownlint only
just lint-yaml          # Yamllint only
just backend-install-uv # Sync backend dev dependencies with uv
just backend-check      # Run backend ruff + ty + pytest
just backend-check-ci   # Run backend CI script locally
just backend-test-coverage # Run backend tests with coverage summary
just backend-check-coverage # Run backend lint + typecheck + coverage tests
just backend-clean      # Remove generated backend runtime/build artifacts
just ios-test-ci        # Run iOS CI-style test lane locally
just ci-local           # Run lint + backend checks + iOS tests
just security           # Run Snyk dependency + code scans
just xcode-open         # Open project in Xcode
```

## CI Environment

CI uses pinned simulator configuration (see `scripts/ci/readiness-env.sh`):

- macOS: 14 (GitHub runner)
- Xcode: 16.2
- Simulator: iPhone 16, iOS 18.2
- Architecture: arm64 (Apple Silicon), unpinned (Intel)

Local testing: `just test` sources these values automatically.

## Key Directories

**iOS:**

- `ios/Offload/App/` — Entry point, `MainTabView`
- `ios/Offload/Features/` — Capture, Home, Organize, Settings
- `ios/Offload/Domain/Models/` — SwiftData models
- `ios/Offload/Data/Repositories/` — CRUD repositories
- `ios/Offload/Data/Networking/` — Backend API client and contracts
- `ios/Offload/Data/Persistence/` — SwiftData container setup
- `ios/Offload/Data/Services/` — Voice recording, breakdown, attachment services
- `ios/Offload/Common/` — Shared utilities, repository environment, error handling
- `ios/Offload/DesignSystem/` — Theme, components, icons, textures
- `scripts/ci/` — CI lane scripts (iOS/backend/scripts)

**Backend:**

- `backend/api/src/offload_backend/`
  - `main.py` — FastAPI app entry point
  - `config.py` — Pydantic settings with OFFLOAD_* env vars
  - `dependencies.py` — FastAPI dependency injection
  - `security.py` — Session token v2 management (JWT with key rotation)
  - `session_security.py` — Startup secret validation and environment checks
  - `session_rate_limiter.py` — Session issuance rate limiting
  - `usage_store.py` — Usage tracking persistence
  - `schemas.py` — Pydantic request/response models
  - `errors.py` — API exception types and error handlers
  - `routers/` — FastAPI route modules (breakdown, usage, health)
  - `providers/` — External service adapters (OpenAI with retry)

**Documentation:**

- `docs/product.md` — Product philosophy, features, data model
- `docs/architecture.md` — Tech stack, architectural decisions, CI, backend/privacy
- `docs/design.md` — UX patterns, testing guides
- `docs/plans/backlog.md` — Unplanned items (see `docs/CLAUDE.md`)
- `docs/plans/` — Active plan docs, each covering a unified body of work

## Test Organization

**iOS:**

- `ios/OffloadTests/*RepositoryTests.swift` — Repository CRUD tests
- `ios/OffloadTests/APIClientTests.swift` — Backend API client tests
- `ios/OffloadTests/PerformanceBenchmarkTests.swift` — Performance tests
- `ios/OffloadUITests/` — UI automation tests (note: `testLaunch()` is flaky)

**Backend:**

- `backend/api/tests/test_*.py` — pytest modules
- `backend/api/tests/conftest.py` — pytest fixtures and test config

## Gotchas

- **NEVER commit directly to main branch** - always use feature branches for all work
- Always clean up merged branches
- For GitHub issue/PR descriptions created via `gh`: use `--body-file` (or a heredoc with real line breaks) and never pass escaped `\n` sequences as body text
- Pre-commit hygiene: run `markdownlint --fix` for doc changes, `yamllint` for YAML, and use conventional atomic commits
- CI markdownlint runs strict (no `--fix`); table column alignment (MD060) must be manually correct
- Markdownlint MD036: Don't use bold text for section headers (`**Section:**`) - use proper headings (`### Section`)
- Worktree git operations require `cd` to worktree path; `gh pr create` fails if PR already exists (push updates existing PR)
- **Worktree workflow**: Standard pattern is `git worktree add .worktrees/<name> -b <branch>` → implement → test → commit → `git worktree remove .worktrees/<name>`
- For feature implementation, use TDD (red → green → refactor): write tests
  first, implement the minimal code to pass, then refactor with tests green
- Use Conventional Commits format: `type(scope): description` (e.g., `fix(ux): restore swipe-to-delete`, `feat(voice): add @MainActor isolation`)
- Use conventional branch prefixes: `feat/`, `fix/`, `docs/`, `chore/` (e.g., `feat/swipe-delete`, `fix/gesture-conflict`)
- **When creating new GitHub issues, always add them to the Offload project** using `gh issue create --project "Offload"` during creation, or `gh issue edit <number> --add-project "Offload"` after creation
- **When creating new GitHub issues, always apply labels at creation time; never leave issues unlabeled**
- Use `bug` for defects/regressions, `enhancement` for feature or implementation work, and `documentation` for docs-only work
- Use `ux` as an additional label (with one of the primary labels above) for UX/UI-focused issues
- If label selection is ambiguous, ask the user before creating or relabeling issues
- After any issue/PR/project update, run an issue sync audit and fix mismatches:
  open issues in project, no unlabeled open issues, open issues not in `Done`/`Archived`,
  closed issues in `Done`/`Archived`, and `In review` only when a related PR is open
- For backend persistence, security, or provider-resilience changes: run
  `just backend-check-coverage` before opening/updating PRs
- Never commit generated backend runtime/build artifacts (`.offload-backend/`,
  `backend/api/.offload-backend/`, `backend/api/src/offload_backend_api.egg-info/`);
  use `just backend-clean` when needed
- **App is pre-production / early-stage**: do not propose or implement SwiftData versioned-schema migrations, `SchemaMigrationPlan`, `willMigrate` hooks, or staged data migration strategies. Modify models directly. If existing docs reference migration complexity, simplify them.
- SwiftData predicates require explicit type references for enum cases
- Repositories must be injected via `@State` + `.task`, not created in `body`
- `.draggable()` must be on card content directly, not on wrappers with buttons
- Editing `Domain/Models/*.swift` may require SwiftData migration
- `.accessibilityCustomAction` fails after `.contextMenu{}` — use `.accessibilityAction(named:)` instead
- `@Environment(\.accessibilityReduceMotion)` only works in Views; use `UIAccessibility.isReduceMotionEnabled` in classes (e.g., ThemeManager)
- OSLog `privacy:` only works inside string interpolation `\(value, privacy: .public)`, not as a standalone log argument
- xcodebuild requires `-project ios/Offload.xcodeproj`; repo root has no `.xcodeproj`
- `just test` may fail if multiple simulators share the same name; run directly with OS: `xcodebuild test -project ios/Offload.xcodeproj -scheme Offload -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.2'`
- `OffloadUITestsLaunchTests.testLaunch()` is flaky (screenshot comparison); failures don't indicate real regressions
- To find SF Symbol icon names, grep Icons.swift: `grep -i "trash" ios/Offload/DesignSystem/Icons.swift`
- SwiftUI gesture composition: use `.simultaneousGesture()` for multiple gestures; `abs(dx) > abs(dy)` differentiates horizontal from vertical
- New or modified production functions/methods should include concise doc comments covering purpose, key parameters, and return behavior when not `Void`

## Design System Rules

### Aesthetic

Mid-Century Modern (MCM): bold warm colors, geometric fonts, flat design with borders over shadows, retro textures at subtle opacity.

### Token Usage (IMPORTANT)

All styling MUST use `Theme.*` tokens — never hardcode colors, fonts, spacing, or radii.

```swift
// Required at top of every view that uses theme tokens
@Environment(\.colorScheme) private var colorScheme
@EnvironmentObject private var themeManager: ThemeManager
private var style: ThemeStyle { themeManager.currentStyle }

// Correct
.foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))
.background(Theme.Surface.card(colorScheme, style: style))
.padding(Theme.Spacing.md)
.clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))

// WRONG — never do this
.foregroundStyle(.black)
.padding(16)
.cornerRadius(12)
```

### Colors

| Token | Purpose |
| --- | --- |
| `Theme.Colors.accentPrimary` | Primary burnt orange |
| `Theme.Colors.accentSecondary` | Avocado green |
| `Theme.Colors.textPrimary/Secondary` | Text hierarchy |
| `Theme.Surface.background/card` | Backgrounds |
| `Theme.Colors.cardColor(index:)` | 5-color cycling palette for card backgrounds |
| `Theme.Colors.success/caution/destructive` | Semantic states |
| `Theme.Colors.accentButtonText/secondaryButtonText` | Contrast-safe text on accent/secondary backgrounds |
| `Theme.Colors.semanticButtonText/cautionButtonText` | Contrast-safe text on semantic color backgrounds |

Never use `.foregroundStyle(.white)` on colored backgrounds — use the contrast-safe helpers above which adapt for dark mode.

### Typography

| Token | Font | Use |
| --- | --- | --- |
| `Theme.Typography.largeTitle/title/title2` | Bebas Neue | Display headings |
| `Theme.Typography.body/callout/subheadline` | Space Grotesk | Body text |
| `Theme.Typography.cardTitle/cardTitleEmphasis` | Bebas Neue | Card headings |
| `Theme.Typography.cardBody` | Space Grotesk | Card content |
| `Theme.Typography.buttonLabel` | Space Grotesk | Button text |
| `Theme.Typography.badge/metadata/timestampMono` | Space Grotesk | Small/monospaced |

### Spacing

`xs:4 sm:8 md:18 lgSoft:20 lg:24 xl:32 xxl:48` — always use `Theme.Spacing.*`.

### Corner Radius

`sm:16 md:20 lg:24 xl:32 cardSoft:32 pill:100` — always use `Theme.CornerRadius.*`.

### Components (IMPORTANT)

Reuse components from `DesignSystem/Components.swift` — do not recreate:

- **CardSurface** — Base card container (fill, edge pattern, border, texture)
- **MCMCardContent** — Two-column card layout (`.standard` or `.compact` size)
- **FloatingActionButton** — Primary CTA capsule with gradient border
- **ItemActionButton** — Small circular icon button (`.primaryFilled`/`.secondaryOutlined`/`.plain`)
- **IconTile** — Icon in rounded container for toolbars
- **TagPill** — Capsule tag with gradient fill
- **TypeChip** — Smaller metadata pill
- **FlowLayout** — Wrapping layout for tags
- **EmptyStateView** — Icon + message + optional action
- **ToastView** — Auto-dismissing notification (via `ToastManager`)

### Icons

Use SF Symbol constants from `DesignSystem/Icons.swift` (e.g., `Icons.add`, `Icons.star`). Do NOT add icon packages.

### Textures

Cards get `.cardTexture(colorScheme)` (linen overlay, 0.02-0.03 opacity). Respects `accessibilityReduceMotion`.

### Shadows

Minimal — prefer `showsBorder` on `CardSurface` over shadows. If needed: `Theme.Shadows.ultraLight(colorScheme)` (color function) or elevation constants `Theme.Shadows.elevationXs/elevationSm/elevationMd`.

### Animations

Use `Theme.Animations.*`: `springDefault` (0.3s), `springSnappy` (0.2s), `mechanicalSlide` (0.4s), `snapToGrid`.

All animations MUST respect reduced motion. Use `Theme.Animations.motion(animation, reduceMotion: reduceMotion)` to guard `withAnimation`/`.animation()` calls. Add `@Environment(\.accessibilityReduceMotion) private var reduceMotion` to every view with animations.

### New View Checklist

1. Inject `colorScheme`, `themeManager`, compute `style`
2. Use `Theme.Surface.background` as base + deep gradient if full-screen
3. Build cards with `CardSurface` + `MCMCardContent`
4. Apply cycling palette via `Theme.Colors.cardColor(index:)`
5. Use `Theme.Typography.*` for all text
6. Add `.cardTexture(colorScheme)` to cards
7. Use existing components before creating new ones
8. Add `@Environment(\.accessibilityReduceMotion)` and guard all animations
9. Add `.accessibilityLabel`/`.accessibilityValue`/`.accessibilityHint` to interactive elements
10. Use contrast-safe text helpers (`accentButtonText`, etc.) on colored backgrounds

### Figma Integration Rules

1. Get design context + screenshot from Figma before implementing
2. Translate Figma output into SwiftUI using this project's Theme tokens
3. Map Figma colors to `Theme.Colors.*` — never use hex literals
4. Reuse components from `DesignSystem/Components.swift`
5. Store downloaded assets in `ios/Offload/Resources/Assets.xcassets`
6. Use SF Symbols from `Icons.swift` — do NOT add icon packages
7. Validate final UI against Figma screenshot for 1:1 parity

## Documentation Governance

All agent behavior related to documentation under `docs/` is governed by `docs/CLAUDE.md` (AUTHORITATIVE). If this file conflicts with `docs/CLAUDE.md` for documentation behavior, `docs/CLAUDE.md` wins.

Agents MUST follow `docs/CLAUDE.md` when reading, writing, restructuring, or interpreting documentation. This file governs repository-wide and code-level behavior only.

## Agent-Readable Headers

Add agent-readable headers to non-Markdown config files that agents read/modify:

**YAML/TOML:**

```yaml
# File: docs/index.yaml
# Role: Documentation navigation index
# Authority: Navigation only (not source of truth)
# Governed by: CLAUDE.md
# Additional instructions: Additional instructions
```

**JSON:**

```json
{
  "_meta": {
    "role": "reference",
    "authority": "highest",
    "governed_by": "CLAUDE.md",
    "additional_instructions": "Additional instructions"
  }
}
```

**ENV/INI/conf/text/other:**

```text
# Purpose: Runtime configuration defaults
# Authority: Config-level
# Governed by: CLAUDE.md
# Additional instructions
```

## Agent Handoff Summary

- **Primary views**: `HomeView` (dashboard), `CaptureView` (inbox), `OrganizeView` (plans/lists), `CollectionDetailView` (detail), `SettingsView`
- **Design system**: `ios/Offload/DesignSystem/Theme.swift` and `Components.swift`; theme is `midCenturyModern`
- **Data model**: `Item.type == nil` = captures; `Collection.isStructured` distinguishes plans vs lists; `CollectionItem` stores order (`position`) and hierarchy (`parentId`)
- **Relationships**: `Collection.collectionItems` and `Item.collectionItems` use `@Relationship` with cascade delete; `Collection.sortedItems` is canonical ordering
- **Persistence**: Views use `@Query` for reactive data and `@Environment(\.itemRepository)` etc. for mutations
- **Repositories**: Injected via `RepositoryEnvironment.swift`; CRUD in `ios/Offload/Data/Repositories/`
- **Capture flow**: Creates `Item` records (type nil), can attach photo/voice, moves to plan/list via `CollectionItem` link
