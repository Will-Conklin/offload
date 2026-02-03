---
id: research-ios-quick-entry
type: research
status: active
owners:
  - TBD
applies_to:
  - ios
  - research
last_updated: 2026-01-26
related:
  - prd-0001-product-requirements
depends_on:
  - docs/prds/prd-0001-product-requirements.md
supersedes: []
accepted_by: null
accepted_at: null
related_issues: []
structure_notes:
  - "Section order: Summary; Quick Entry Mechanisms; Implementation Priority;
    Technical Requirements; Sources."
---

# Research: iOS Quick Entry Mechanisms

## Summary

This document catalogs iOS platform features that enable rapid item capture from
outside the main app context. These mechanisms reduce friction for users who
want to quickly offload a thought without navigating through the full app UI.

The primary mechanisms investigated are:

1. **Share Extension** — Receive content shared from other apps
2. **App Intents / Siri** — Voice-activated commands
3. **Shortcuts Integration** — User-created and app-provided automations
4. **Widgets** — Home Screen, Lock Screen, and Control Center presence
5. **Control Center Controls** — iOS 18+ quick action buttons
6. **Action Button** — Hardware button on iPhone 15 Pro+
7. **Spotlight Integration** — Search-based quick actions
8. **Live Activities / Dynamic Island** — Persistent capture sessions

---

## Quick Entry Mechanisms

### 1. Share Extension

**What it does:** Allows users to share content (text, URLs, images, files)
from any app directly into Offload via the system share sheet.

**Key characteristics:**

- Runs as a separate process from the main app
- Must configure its own SwiftData model container (cannot inherit from main
  app)
- Uses App Groups for data sharing between extension and main app
- SwiftUI views require wrapping in `UIHostingController`
- No Xcode Previews support within the extension target
- Memory limit: ~120 MB (extensions are terminated if exceeded)

**Implementation approach:**

1. Add Share Extension target in Xcode (File → New → Target → Share Extension)
2. Replace `SLComposeServiceViewController` with `UIViewController`
3. Create SwiftUI view hosted via `UIHostingController`
4. Configure shared App Group container for SwiftData
5. Handle `NSExtensionItem` attachments for text, URLs, images
6. Dismiss extension after saving item

**SwiftData considerations:**

```swift
// Extension must create its own container
let container = try ModelContainer(
    for: Item.self,
    configurations: ModelConfiguration(
        groupContainer: .identifier("group.wc.Offload")
    )
)
```

**User experience:** User selects "Share" from any app → picks Offload from
share sheet → optional: adds note → content saved as new capture item.

---

### 2. App Intents / Siri Voice Commands

**What it does:** Enables hands-free capture via Siri voice commands and
integration with Shortcuts, Spotlight, and the Action button.

**Framework evolution:**

- **SiriKit** (legacy, iOS 10+): Domain-based intents with Intent Definition
  files
- **App Intents** (modern, iOS 16+): Swift-native, no Intent Definition files,
  code-is-truth

**App Intents advantages:**

- Pure Swift implementation with protocols and result builders
- Automatic Siri, Shortcuts, Spotlight, and Action button integration
- Rich parameter types via `@Parameter` wrapper
- SwiftUI views for intent results via `ProvidesDialog`
- Works seamlessly with SwiftUI apps

**Implementation approach:**

1. Enable Siri capability in Signing & Capabilities
2. Create struct conforming to `AppIntent` protocol
3. Define parameters with `@Parameter` wrapper
4. Implement `perform()` async function
5. Create `AppShortcut` for Siri phrase discovery
6. Request Siri authorization at appropriate time

**Example intent structure:**

```swift
struct CaptureThoughtIntent: AppIntent {
    static var title: LocalizedStringResource = "Capture Thought"
    static var description = IntentDescription("Quickly capture a thought")

    @Parameter(title: "Content")
    var content: String

    static var parameterSummary: some ParameterSummary {
        Summary("Capture \(\.$content)")
    }

    func perform() async throws -> some IntentResult {
        // Save to SwiftData
        return .result(dialog: "Captured: \(content)")
    }
}

struct OffloadShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CaptureThoughtIntent(),
            phrases: [
                "Capture \(\.$content) in \(.applicationName)",
                "Add \(\.$content) to \(.applicationName)"
            ],
            shortTitle: "Capture Thought",
            systemImageName: "brain.head.profile"
        )
    }
}
```

**User experience:** User says "Hey Siri, capture 'buy groceries' in Offload"
→ Siri confirms capture → item saved without opening app.

---

### 3. Shortcuts Integration

**What it does:** Exposes app actions to the Shortcuts app for user-created
automations and system integrations.

**Integration points:**

- Shortcuts app (user-created workflows)
- Spotlight search (run shortcuts directly)
- Home Screen shortcuts
- Action button assignment
- Focus mode automations
- Time-based automations

**Implementation:** Covered by App Intents above. Any `AppIntent` with an
`AppShortcut` automatically appears in Shortcuts app.

**Advanced capabilities:**

- Chain Offload actions with other apps (e.g., transcribe voice memo → capture)
- Trigger captures based on location, time, or Focus mode
- Batch operations (process multiple items)
- Export captures to other apps

**User experience:** User creates Shortcut "Morning Brain Dump" → triggers
Offload capture intent → adds to specific collection automatically.

---

### 4. Widgets (WidgetKit)

**What it does:** Provides glanceable information and quick actions on Home
Screen, Lock Screen, and StandBy mode.

**Widget types:**

| Type               | Sizes          | Interactivity | Text Input |
|--------------------|----------------|---------------|------------|
| Home Screen        | Small/Med/Lrg  | Buttons/Toggle| No         |
| Lock Screen        | Circular/Rect  | Buttons/Toggle| No         |
| StandBy            | Same as Lock   | Buttons/Toggle| No         |

**iOS 17+ interactivity:**

- `Button` and `Toggle` only (no text fields, sliders, or gestures)
- Actions execute via App Intents directly in widget (no app launch)
- Locked device: buttons inactive until unlocked

**Practical widget concepts for Offload:**

1. **Quick Capture Button** — Taps to open app at capture screen (deep link)
2. **Recent Captures** — Shows last N items with tap-to-open
3. **Voice Capture** — Button to start voice recording (opens app)
4. **Star/Complete Toggle** — Mark recent items without opening app

**Implementation considerations:**

- Widgets share SwiftData via App Groups (same as Share Extension)
- Timeline-based updates; not real-time
- Use `AppIntentTimelineProvider` for intent-driven refresh

**Limitation:** Cannot directly input text in widgets. Tap actions must either
launch app or trigger pre-defined App Intents.

---

### 5. Control Center Controls (iOS 18+)

**What it does:** Adds quick-action buttons to Control Center, Lock Screen
bottom row, and Action button assignment.

**Key characteristics:**

- Built with WidgetKit (same framework as widgets)
- Supports buttons and toggles only
- Can be assigned to iPhone Action button
- Appears in Control Center controls gallery

**Implementation approach:**

1. Create ControlWidget in WidgetKit extension
2. Conform to `ControlWidget` protocol
3. Define button action via App Intent
4. Add to widget bundle

**Example control:**

```swift
struct CaptureControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "CaptureControl") {
            ControlWidgetButton(action: OpenCaptureIntent()) {
                Label("Capture", systemImage: "plus.circle")
            }
        }
        .displayName("Quick Capture")
        .description("Open Offload capture screen")
    }
}
```

**User experience:** User swipes to Control Center → taps Offload button →
app opens to capture screen (or triggers voice recording intent).

---

### 6. Action Button (iPhone 15 Pro+)

**What it does:** Hardware button that can trigger any App Intent or Shortcut.

**How it works:**

- User assigns action in Settings → Action Button
- Can run any App Shortcut from your app
- Can run user-created Shortcuts
- Supports Controls (iOS 18+)

**Implementation:** No special code required beyond App Intents. Users discover
and assign your app's shortcuts themselves.

**User experience:** User assigns "Capture Thought" shortcut to Action button →
long-press Action button → Siri prompts for thought → saved without unlocking.

---

### 7. Spotlight Integration

**What it does:** Makes app content and actions discoverable via system search.

**Integration methods:**

1. **App Shortcuts in Spotlight** — Run shortcuts from search
2. **Indexed Entities (iOS 18+)** — Search app content directly
3. **NSUserActivity** — Index viewed content for Handoff/search

**iOS 18 IndexedEntity:**

```swift
struct CaptureEntity: AppEntity, IndexedEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Capture")

    var id: UUID
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(content)")
    }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet()
        attributes.displayName = content
        attributes.contentDescription = "Offload capture"
        return attributes
    }
}
```

**User experience:** User searches "grocery list" in Spotlight → sees Offload
capture matching that content → taps to open directly in app.

---

### 8. Live Activities / Dynamic Island

**What it does:** Displays persistent, updating information on Lock Screen and
Dynamic Island during active capture sessions.

**Use cases for Offload:**

- **Ongoing capture session** — Show active voice recording status
- **Capture reminder** — Persistent "capture in progress" during extended input
- **Task list mode** — Show items being checked off (like Funnel app)

**Characteristics:**

- Maximum duration: 8 hours active, 12 hours total on Lock Screen
- Updates via push notification or local updates
- Limited to compact UI (no text input)
- Available on iPhone 14 Pro+ for Dynamic Island

**When to use:** Best for extended capture sessions (voice memos, multi-item
brain dumps) rather than single quick captures.

---

## Implementation Priority

Based on user friction reduction and implementation complexity:

### Phase 1: High Impact, Moderate Effort

| Feature              | Impact | Effort | Notes                           |
|----------------------|--------|--------|---------------------------------|
| Share Extension      | High   | Medium | Core quick-entry from any app   |
| App Intents / Siri   | High   | Medium | Voice capture, Shortcut support |
| Control Center       | High   | Low    | Leverages App Intents work      |

### Phase 2: Enhanced Discoverability

| Feature              | Impact | Effort | Notes                           |
|----------------------|--------|--------|---------------------------------|
| Home Screen Widget   | Medium | Medium | Glanceable + quick launch       |
| Lock Screen Widget   | Medium | Low    | Quick access when locked        |
| Spotlight Indexing   | Medium | Medium | Find captures via search        |

### Phase 3: Power User Features

| Feature              | Impact | Effort | Notes                           |
|----------------------|--------|--------|---------------------------------|
| Live Activities      | Low    | High   | Niche: extended capture sessions|
| Advanced Shortcuts   | Low    | Low    | Power user automations          |

---

## Technical Requirements

### Shared Infrastructure

All quick-entry mechanisms require:

1. **App Groups** — Shared container for SwiftData between app and extensions
2. **SwiftData Configuration** — Model container configured for group container
3. **Deep Links** — URL scheme for navigating to specific app screens
4. **App Intents** — Common intent library shared across all entry points

### Capability Additions

| Feature         | Capability Required          |
|-----------------|------------------------------|
| Share Extension | Share Extension target       |
| Siri/Shortcuts  | Siri capability              |
| Widgets         | Widget Extension target      |
| Control Center  | Widget Extension (iOS 18+)   |
| App Groups      | App Groups entitlement       |

### Minimum iOS Versions

| Feature         | Minimum iOS | Recommended |
|-----------------|-------------|-------------|
| Share Extension | iOS 8       | iOS 17+     |
| App Intents     | iOS 16      | iOS 17+     |
| Shortcuts       | iOS 13      | iOS 17+     |
| Widgets         | iOS 14      | iOS 17+     |
| Interactive     | iOS 17      | iOS 17+     |
| Control Center  | iOS 18      | iOS 18+     |
| Live Activities | iOS 16.1    | iOS 17+     |

---

## Sources

### Share Extension

- [iOS Share Extension with SwiftUI and SwiftData](https://www.merrell.dev/ios-share-extension-with-swiftui-and-swiftdata/)
- [Create an iOS Share Extension with custom UI in Swift and SwiftUI](https://medium.com/@henribredtprivat/create-an-ios-share-extension-with-custom-ui-in-swift-and-swiftui-2023-6cf069dc1209)
- [Implementing a SwiftUI ShareSheet Extension](https://agtlucas.com/blog/implementing-a-swift-ui-sharesheet-extension/)
- [Implementing a share extension with SwiftUI](https://kait.dev/posts/implementing-swiftui-share-extension)
- [Sharing Data Between Share Extension & App](https://www.fleksy.com/blog/communicating-between-an-ios-app-extensions-using-app-groups/)

### App Intents / Siri

- [Apple Developer: App Intents](https://developer.apple.com/documentation/appintents)
- [Hey Siri, How Do I Use App Intents?](https://instil.co/blog/siri-with-app-intents/)
- [Unlock the Power of Siri with AppIntents](https://purvesh-dodiya.medium.com/unlock-the-power-of-siri-in-ios-app-a-beginners-guide-to-siri-integration-with-appintents-in-5bd4945e127f)
- [WWDC24: What's new in App Intents](https://developer.apple.com/videos/play/wwdc2024/10134/)
- [WWDC24: Bring your app's core features to users with App Intents](https://developer.apple.com/videos/play/wwdc2024/10210/)
- [App Intents Tutorial: A Field Guide for iOS Developers](https://superwall.com/blog/an-app-intents-field-guide-for-ios-developers/)

### Shortcuts

- [How to Integrate Siri Shortcuts into Your SwiftUI App](https://www.bitcot.com/siri-shortcuts-in-swiftui/)
- [App Intents Spotlight integration using Shortcuts](https://www.avanderlee.com/swiftui/app-intents-spotlight-integration-using-shortcuts/)
- [Apple Developer: App Shortcuts](https://developer.apple.com/documentation/appintents/app-shortcuts)

### Widgets

- [Apple Developer: Adding Interactivity to Widgets](https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities)
- [Interactive Widgets With SwiftUI (Kodeco)](https://www.kodeco.com/43771410-interactive-widgets-with-swiftui)
- [Building Widgets for iOS 17](https://commitstudiogs.medium.com/building-widgets-for-ios-17-making-use-of-the-newest-widget-features-8999a6224881)
- [Apple Developer: WidgetKit](https://developer.apple.com/widgets/)

### Control Center

- [Apple Developer: Extend your app's controls across the system (WWDC24)](https://developer.apple.com/videos/play/wwdc2024/10157/)
- [Exploring WidgetKit: Creating Your First Control Widget in iOS 18](https://rudrank.com/exploring-widgetkit-first-control-widget-ios-18-swiftui)
- [Apple Developer: ControlCenter Documentation](https://developer.apple.com/documentation/widgetkit/controlcenter)

### Action Button

- [Apple Developer: Action button on iPhone and Apple Watch](https://developer.apple.com/documentation/appintents/actionbutton)
- [iPhone Action button shortcuts](https://www.cultofmac.com/how-to/iphone-action-button-shortcuts)

### Live Activities

- [Apple Developer: Displaying live data with Live Activities](https://developer.apple.com/documentation/activitykit/displaying-live-data-with-live-activities)
- [Integrating Live Activity and Dynamic Island in iOS](https://canopas.com/integrating-live-activity-and-dynamic-island-in-i-os-a-complete-guide)
- [WWDC23: Design dynamic Live Activities](https://developer.apple.com/videos/play/wwdc2023/10194/)

### Spotlight

- [WWDC23: Spotlight your app with App Shortcuts](https://developer.apple.com/videos/play/wwdc2023/10102/)
- [Using App Intents in a SwiftUI app](https://www.createwithswift.com/using-app-intents-swiftui-app/)

### Example Apps

- [Funnel - Quick Capture App](https://apps.apple.com/us/app/funnel-quick-capture/id6466168248) — Reference implementation with Dynamic Island support
