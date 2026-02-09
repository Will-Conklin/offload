# Project: Offload

iOS app built with SwiftUI and SwiftData (iPhone + iPad).

## Quick Reference

- **Bundle ID**: wc.Offload
- **Pattern**: Feature-based modules with repository pattern
- **Navigation**: `MainTabView` → `NavigationStack` → sheets
- **Models**: Item, Collection, CollectionItem, Tag (SwiftData)
- **Design system**: `DesignSystem/Theme.swift`, theme `midCenturyModern`

## Commands

```bash
just                    # List all commands
just build              # Build (Debug, iOS Simulator)
just test               # Run tests (needs concrete simulator — see note)
# Note: `just test` needs a concrete simulator. To run tests:
# xcodebuild test -project ios/Offload.xcodeproj -scheme Offload -destination 'platform=iOS Simulator,name=iPhone 16'
just lint               # Run markdownlint + yamllint
just lint-docs          # Markdownlint only
just lint-yaml          # Yamllint only
just xcode-open         # Open project in Xcode
```

## Key Directories

- `ios/Offload/App/` — Entry point, `MainTabView`
- `ios/Offload/Features/` — Capture, Home, Organize, Settings
- `ios/Offload/Domain/Models/` — SwiftData models
- `ios/Offload/Data/Repositories/` — CRUD repositories
- `ios/Offload/DesignSystem/` — Theme, components, icons, textures
- `docs/` — PRDs, ADRs, designs, plans (see `docs/AGENTS.md`)

## Gotchas

- SwiftData predicates require explicit type references for enum cases
- Repositories must be injected via `@State` + `.task`, not created in `body`
- `.draggable()` must be on card content directly, not on wrappers with buttons
- Editing `Domain/Models/*.swift` may require SwiftData migration
- `.accessibilityCustomAction` fails after `.contextMenu{}` — use `.accessibilityAction(named:)` instead
- `@Environment(\.accessibilityReduceMotion)` only works in Views; use `UIAccessibility.isReduceMotionEnabled` in classes (e.g., ThemeManager)
- OSLog `privacy:` only works inside string interpolation `\(value, privacy: .public)`, not as a standalone log argument

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
| `Theme.Colors.accent` | Primary burnt orange |
| `Theme.Colors.accentSecondary` | Avocado green |
| `Theme.Colors.textPrimary/Secondary/Tertiary` | Text hierarchy |
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
| `Theme.Typography.badge/metadata/timestamp` | Space Grotesk | Small/monospaced |

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

Minimal — prefer `showsBorder` on `CardSurface` over shadows. If needed: `Theme.Shadows.ultraLight/xs/sm/md`.

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

## Full project directives: [AGENTS.md](AGENTS.md)
