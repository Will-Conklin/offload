> **⚠️ DEPRECATED:** This document has been superseded by [master-plan.md](./master-plan.md) as of January 9, 2026.
> Please refer to the master plan for the single source of truth on all implementation planning.

# Offload Polish Phase Implementation Plan

**Goal:** Ship a polished, production-ready manual organization app with excellent UX, accessibility, and visual design.

**Timeline:** 4 weeks of focused polish work

---

## Audit Results

### Issues Found

**Design System (CRITICAL):**
- ✅ Colors: Defined for light/dark mode in Theme.swift
- ❌ Typography: Completely stubbed (4 TODOs)
- ⚠️ Hardcoded colors in 8 files:
  - `InboxView.swift:112` - `.blue.opacity(0.2)` for lifecycle badge
  - `OrganizeView.swift:137` - `.blue.opacity(0.2)` for list kind badge
  - `OrganizeView.swift:169` - `.blue` for communication icon
  - `OrganizeView.swift:175` - `.green` for sent checkmark
  - `SettingsView.swift:78` - `.blue` for app icon
  - Form sheets (5 files) - `.red` for error messages
  - `Components.swift` - `.blue` and `.white` in button components

**Components (CRITICAL):**
- ✅ Have: PrimaryButton, SecondaryButton, CardView (basic)
- ❌ Missing: 15 TODOs for essential components
  - Input fields (TextField, TextEditor wrappers)
  - Navigation (custom nav bar, bottom sheet, modal)
  - Feedback (loading, empty state, error, toast, progress)
  - Button variants (text, icon, floating action)
  - Card variants

**Error Handling (HIGH):**
- ⚠️ Inconsistent error display:
  - Form sheets show errors inline (good)
  - InboxView catches errors but doesn't display them
  - No toast/alert patterns for transient errors
  - No retry mechanisms

**Performance (HIGH):**
- 🐛 Race condition in InboxView:68-84
  - Multiple async tasks spawned inside `withAnimation`
  - `loadInbox()` called multiple times inefficiently
- ⚠️ SwiftData limitations:
  - Fetch-all-then-filter pattern won't scale
  - No migration strategy

**Data Management (MEDIUM):**
- ❌ No export functionality (JSON, text, CSV)
- ❌ No backup/restore
- ⚠️ Archive functions stubbed in SettingsView but not implemented

**Accessibility (MEDIUM):**
- ❓ No VoiceOver labels on custom components
- ❓ Dynamic Type not verified across all views
- ❓ Reduce Motion support missing
- ✅ Hit targets likely meet 44pt minimum (using Theme.HitTarget)

**Configuration (LOW):**
- ⚠️ Hardcoded locale: `en-US` in VoiceRecordingService
- ⚠️ No dev/staging/prod environment config
- ⚠️ API endpoint in AppStorage but no backend

---

## Phase 1: Design System Foundation (Week 1)

### 1.1 Complete Typography System

**File:** `ios/Offload/DesignSystem/Theme.swift`

**Add:**
```swift
struct Typography {
    // Font Families
    static let systemFont = "System"

    // Text Styles with Dynamic Type support
    static let largeTitle = Font.largeTitle
    static let title = Font.title
    static let title2 = Font.title2
    static let title3 = Font.title3
    static let headline = Font.headline
    static let body = Font.body
    static let callout = Font.callout
    static let subheadline = Font.subheadline
    static let footnote = Font.footnote
    static let caption = Font.caption
    static let caption2 = Font.caption2

    // Custom Semantic Styles
    static let cardTitle = Font.headline
    static let cardBody = Font.subheadline
    static let buttonLabel = Font.headline
    static let inputLabel = Font.subheadline
    static let errorText = Font.caption

    // Line Heights (using .lineSpacing modifier)
    static let lineHeightTight: CGFloat = 0.8
    static let lineHeightNormal: CGFloat = 1.0
    static let lineHeightRelaxed: CGFloat = 1.5
}
```

**Impact:** Enables consistent typography across all views

---

### 1.2 Create Theme Extension for Environment Access

**File:** `ios/Offload/DesignSystem/ThemeEnvironment.swift` (NEW)

**Purpose:** Allow views to access theme colors without @Environment(\.colorScheme)

```swift
import SwiftUI

extension View {
    func themedBackground(_ colorScheme: ColorScheme) -> some View {
        self.background(Theme.Colors.background(colorScheme))
    }

    func themedForeground(_ style: ThemeTextStyle, _ colorScheme: ColorScheme) -> some View {
        switch style {
        case .primary:
            self.foregroundStyle(Theme.Colors.textPrimary(colorScheme))
        case .secondary:
            self.foregroundStyle(Theme.Colors.textSecondary(colorScheme))
        }
    }
}

enum ThemeTextStyle {
    case primary
    case secondary
}
```

---

### 1.3 Replace Hardcoded Colors

**Files to update (8 files):**

1. **InboxView.swift:112**
   ```swift
   // Before
   .background(Color.blue.opacity(0.2))

   // After
   @Environment(\.colorScheme) var colorScheme
   .background(Theme.Colors.accentPrimary(colorScheme).opacity(0.2))
   ```

2. **OrganizeView.swift:137, 169**
   ```swift
   // Replace .blue with Theme.Colors.accentPrimary(colorScheme)
   // Replace .green with Theme.Colors.success(colorScheme)
   ```

3. **SettingsView.swift:78**
   ```swift
   .foregroundStyle(Theme.Colors.accentPrimary(colorScheme))
   ```

4. **All form sheets (5 files)** - error messages
   ```swift
   .foregroundStyle(Theme.Colors.destructive(colorScheme))
   ```

5. **Components.swift** - buttons
   ```swift
   // Update PrimaryButton and SecondaryButton to use theme colors
   ```

**Acceptance Criteria:**
- Zero grep results for hardcoded `Color.blue`, `Color.red`, `Color.green`
- App works identically in light/dark mode
- All colors sourced from Theme.Colors

---

## Phase 2: Component Library (Week 1-2)

### 2.1 Input Components

**File:** `ios/Offload/DesignSystem/Components.swift`

**Add:**

```swift
// MARK: - Input Fields

struct ThemedTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Theme.Typography.inputLabel)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme))

            TextField(placeholder, text: $text)
                .font(Theme.Typography.body)
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.surface(colorScheme))
                .cornerRadius(Theme.CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .stroke(Theme.Colors.borderMuted(colorScheme), lineWidth: 1)
                )
        }
    }
}

struct ThemedTextEditor: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var minHeight: CGFloat = 100

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Theme.Typography.inputLabel)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme))

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme).opacity(0.5))
                        .padding(Theme.Spacing.sm)
                }

                TextEditor(text: $text)
                    .font(Theme.Typography.body)
                    .frame(minHeight: minHeight)
                    .padding(Theme.Spacing.sm)
                    .scrollContentBackground(.hidden)
                    .background(Theme.Colors.surface(colorScheme))
            }
            .cornerRadius(Theme.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(Theme.Colors.borderMuted(colorScheme), lineWidth: 1)
            )
        }
    }
}
```

---

### 2.2 Feedback Components

**Add to Components.swift:**

```swift
// MARK: - Feedback

struct LoadingView: View {
    var message: String = "Loading..."

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
            Text(message)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background(colorScheme))
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)?
    var actionLabel: String?

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme))

            Text(title)
                .font(Theme.Typography.title3)
                .foregroundStyle(Theme.Colors.textPrimary(colorScheme))

            Text(message)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)

            if let action, let label = actionLabel {
                Button(action: action) {
                    Text(label)
                        .font(Theme.Typography.buttonLabel)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Colors.accentPrimary(colorScheme))
                        .cornerRadius(Theme.CornerRadius.md)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background(colorScheme))
    }
}

struct ErrorView: View {
    let error: Error
    var retryAction: (() -> Void)?

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(Theme.Colors.caution(colorScheme))

            Text("Something went wrong")
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textPrimary(colorScheme))

            Text(error.localizedDescription)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.xl)

            if let retry = retryAction {
                Button(action: retry) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .font(Theme.Typography.buttonLabel)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Colors.accentPrimary(colorScheme))
                        .cornerRadius(Theme.CornerRadius.md)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background(colorScheme))
    }
}
```

---

### 2.3 Toast/Alert System

**File:** `ios/Offload/DesignSystem/ToastView.swift` (NEW)

```swift
import SwiftUI

struct ToastView: View {
    let message: String
    let type: ToastType

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: type.icon)
                .foregroundStyle(type.color(colorScheme))

            Text(message)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textPrimary(colorScheme))

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface(colorScheme))
        .cornerRadius(Theme.CornerRadius.lg)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal, Theme.Spacing.md)
    }
}

enum ToastType {
    case success
    case error
    case info
    case warning

    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }

    func color(_ colorScheme: ColorScheme) -> Color {
        switch self {
        case .success: return Theme.Colors.success(colorScheme)
        case .error: return Theme.Colors.destructive(colorScheme)
        case .info: return Theme.Colors.accentPrimary(colorScheme)
        case .warning: return Theme.Colors.caution(colorScheme)
        }
    }
}

// Toast Manager
@Observable
class ToastManager {
    var currentToast: Toast?

    func show(_ message: String, type: ToastType) {
        currentToast = Toast(message: message, type: type)

        Task {
            try? await Task.sleep(for: .seconds(3))
            if currentToast?.id == currentToast?.id {
                currentToast = nil
            }
        }
    }
}

struct Toast: Identifiable {
    let id = UUID()
    let message: String
    let type: ToastType
}

// View Modifier
struct ToastModifier: ViewModifier {
    @State private var toastManager = ToastManager()

    func body(content: Content) -> some View {
        content
            .environment(toastManager)
            .overlay(alignment: .top) {
                if let toast = toastManager.currentToast {
                    ToastView(message: toast.message, type: toast.type)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(), value: toastManager.currentToast)
                        .padding(.top, Theme.Spacing.md)
                }
            }
    }
}

extension View {
    func withToast() -> some View {
        modifier(ToastModifier())
    }
}
```

---

## Phase 3: Error Handling & UX (Week 2)

### 3.1 Fix InboxView Race Condition

**File:** `ios/Offload/Features/Inbox/InboxView.swift`

**Current issue (lines 68-84):**
```swift
private func deleteEntries(offsets: IndexSet) {
    withAnimation {
        for index in offsets {
            // Spawns multiple async tasks inside withAnimation
            _Concurrency.Task {
                try await workflowService.deleteEntry(entry)
                await loadInbox()  // Called N times!
            }
        }
    }
}
```

**Fix:**
```swift
private func deleteEntries(offsets: IndexSet) {
    let entriesToDelete = offsets.map { entries[$0] }

    Task {
        do {
            guard let workflowService = workflowService else { return }

            // Delete all entries sequentially
            for entry in entriesToDelete {
                try await workflowService.deleteEntry(entry)
            }

            // Reload once after all deletions
            await loadInbox()

        } catch {
            toastManager.show("Failed to delete entries", type: .error)
        }
    }
}
```

---

### 3.2 Add Error Display to InboxView

**Add:**
```swift
@Environment(ToastManager.self) private var toastManager

// In loadInbox():
private func loadInbox() async {
    guard let workflowService = workflowService else { return }
    do {
        entries = try workflowService.fetchInbox()
    } catch {
        toastManager.show("Failed to load inbox: \(error.localizedDescription)", type: .error)
    }
}
```

---

### 3.3 Update Form Sheets to Use Toast

**Replace inline error text in all form sheets with toast notifications on save failure**

---

## Phase 4: Data Management (Week 3)

### 4.1 Export Functionality

**File:** `ios/Offload/Data/Services/ExportService.swift` (NEW)

**Features:**
- Export all data as JSON
- Export inbox as text
- Export specific plans/lists as markdown
- Share via iOS share sheet

**Implementation:**
```swift
import SwiftUI
import SwiftData

actor ExportService {
    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func exportAllAsJSON() throws -> Data {
        // Fetch all entities and serialize
        // Return JSON data
    }

    func exportInboxAsText() throws -> String {
        // Fetch inbox entries
        // Format as plain text
    }

    func exportPlanAsMarkdown(_ plan: Plan) -> String {
        // Format plan with tasks as markdown
    }
}
```

---

### 4.2 Backup/Restore

**Add to SettingsView:**
- "Export All Data" button → creates timestamped JSON file
- "Import Data" button → file picker → restore from JSON
- Validation and conflict resolution

---

### 4.3 Archive Implementation

**Implement the stubbed functions in SettingsView:**
```swift
private func clearCompletedTasks() {
    // Delete all completed tasks across all plans
}

private func archiveOldCaptures() {
    // Archive captures older than 30 days
    // Move to archived state or delete
}
```

---

## Phase 5: Accessibility (Week 3)

### 5.1 VoiceOver Support

**Add accessibility labels to:**
- All custom buttons (FloatingActionButton, etc.)
- List items with context
- Icons that convey meaning
- Custom controls

**Example:**
```swift
Button(action: { showingCapture = true }) {
    Image(systemName: "plus.circle.fill")
}
.accessibilityLabel("Capture new thought")
.accessibilityHint("Opens capture screen for text or voice entry")
```

---

### 5.2 Dynamic Type Verification

**Test all views at:**
- Extra Small
- Medium (default)
- Extra Extra Large
- Accessibility sizes (XXXL)

**Fix any:**
- Truncated text
- Overlapping elements
- Fixed-height containers that clip content

---

### 5.3 Reduce Motion Support

**Add to animations:**
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

// In view
.animation(reduceMotion ? .none : .spring(), value: someState)
```

---

## Phase 6: Polish & Refinement (Week 4)

### 6.1 Empty States

**Add EmptyStateView to:**
- InboxView when no captures
- OrganizeView sections when empty
- Search results when no matches

---

### 6.2 Loading States

**Add LoadingView to:**
- Initial app load
- Voice transcription in progress
- Long-running operations

---

### 6.3 Transitions & Animations

**Smooth transitions for:**
- Sheet presentations
- List item deletions
- Tab switches
- Toast appearances

---

### 6.4 Search & Filter

**Add to OrganizeView:**
- Search bar for filtering plans/lists
- Sort options (date, name, completion)
- Filter by category/tag

---

### 6.5 Batch Operations

**Add to OrganizeView:**
- Multi-select mode
- Batch delete
- Batch archive
- Batch categorize

---

## Success Criteria

### Design System
- ✅ Zero hardcoded colors (all use Theme.Colors)
- ✅ Complete typography system
- ✅ 15+ reusable components
- ✅ Light/dark mode parity

### Error Handling
- ✅ Toast notifications for transient errors
- ✅ Error views for failed states
- ✅ No silent failures
- ✅ Clear error messages

### Performance
- ✅ No race conditions
- ✅ Efficient data fetching
- ✅ Smooth 60fps scrolling

### Data Management
- ✅ Export to JSON/text/markdown
- ✅ Backup/restore functionality
- ✅ Archive old data
- ✅ Clear completed tasks

### Accessibility
- ✅ VoiceOver support (all screens navigable)
- ✅ Dynamic Type support (no clipping at XXXL)
- ✅ Reduce Motion support
- ✅ Minimum 44pt hit targets

### UX Polish
- ✅ Empty states for all lists
- ✅ Loading states for async operations
- ✅ Search/filter in OrganizeView
- ✅ Batch operations
- ✅ Smooth animations

---

## Testing Plan

### Manual Testing
1. **Light/Dark Mode:** Test all screens in both modes
2. **Dynamic Type:** Test at 5 different text sizes
3. **VoiceOver:** Navigate entire app with VoiceOver only
4. **Reduce Motion:** Verify animations disabled
5. **Stress Testing:** Create 100+ captures, 50+ plans, verify performance

### Automated Testing
1. **Unit Tests:** Add tests for ExportService, archiving logic
2. **UI Tests:** Add snapshot tests for components in light/dark mode
3. **Accessibility Tests:** Automated VoiceOver navigation tests

---

## Implementation Order

**Week 1: Foundation**
1. Complete typography system
2. Replace all hardcoded colors
3. Build input components
4. Build feedback components
5. Implement toast system

**Week 2: Stability**
1. Fix InboxView race condition
2. Add error handling to all views
3. Integrate toast notifications
4. Build export service
5. Implement backup/restore

**Week 3: Accessibility**
1. Add VoiceOver labels
2. Test Dynamic Type
3. Add Reduce Motion support
4. Implement archive functionality
5. Add empty states

**Week 4: Polish**
1. Search and filter
2. Batch operations
3. Animations and transitions
4. Manual testing at all accessibility sizes
5. Bug fixes and refinement

---

## Release Readiness

After completing this polish phase, Offload will be ready to ship as a **premium manual organization app** with:

- **Professional design system** with excellent light/dark mode support
- **Robust error handling** that guides users clearly
- **Full accessibility** meeting WCAG standards
- **Data portability** with export/backup features
- **Polished UX** with empty states, loading indicators, and smooth animations

This positions Offload for:
1. **App Store submission** as a v1 manual app
2. **User testing** to validate UX before adding AI
3. **Premium pricing** ($2.99-$4.99) based on quality
4. **AI upsell** later as a "Pro" feature

The app becomes immediately useful without AI, then AI becomes a premium enhancement rather than a dependency.
