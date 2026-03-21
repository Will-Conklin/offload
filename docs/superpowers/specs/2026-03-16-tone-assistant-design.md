# Tone Assistant — Design Spec

**Date:** 2026-03-16
**Status:** Approved
**Feature:** AI Organization Flow — Feature 4

---

## Overview

Tone Assistant transforms a capture into a differently-worded version using one of six tones. The user picks a tone, sees the result, then either copies it to the clipboard or saves it as a new capture alongside the original. No presets in v1.

---

## Scope

### In scope

- 6 tones: formal, friendly, concise, empathetic, direct, neutral
- Pick one tone → generate → view result
- Result actions: copy to clipboard, or save as a new capture (original untouched)
- Cloud path via `POST /v1/ai/tone/transform` (opt-in, consistent with other AI features)
- On-device fallback (basic heuristics, clearly labeled)
- Entry point: `ItemCard` context menu + accessibility action (in `CaptureItemCard.swift`)
- Unit tests for service layer, ViewModel, and backend endpoint

### Out of scope (deferred)

- Named presets
- Multiple simultaneous tone previews
- Applying tone in-place (overwriting the original)

---

## Architecture

### New files

| File | Purpose |
| --- | --- |
| `ios/Offload/Data/Services/ToneAssistantService.swift` | `ToneAssistantService` protocol, `DefaultToneAssistantService`, `SimpleOnDeviceToneTransformer`, `ToneStyle` enum |
| `ios/Offload/Features/Capture/ToneAssistantSheet.swift` | `ToneAssistantSheetViewModel` + `ToneAssistantSheet` view |
| `backend/api/src/offload_backend/routers/tone.py` | `POST /v1/ai/tone/transform` FastAPI router |
| `ios/OffloadTests/ToneAssistantServiceTests.swift` | Unit tests for service layer |
| `ios/OffloadTests/ToneAssistantSheetViewModelTests.swift` | Unit tests for ViewModel phase transitions |
| `backend/api/tests/test_tone.py` | Backend endpoint tests |

### Modified files

| File | Change |
| --- | --- |
| `ios/Offload/Data/Networking/AIBackendContracts.swift` | Add `ToneTransformRequest`, `ToneTransformResponse`, `ToneUsage` Codable structs |
| `ios/Offload/Data/Networking/AIBackendClient.swift` | Add `transformTone()` to the `AIBackendClient` protocol; implement it in `NetworkAIBackendClient` |
| `ios/Offload/Common/AIBackendEnvironment.swift` | Add `ToneAssistantServiceKey` + `toneAssistantService` EnvironmentValues accessor |
| `ios/Offload/App/AdvancedAccessibilityActionPolicy.swift` | Add `static let toneActionName = "Rewrite Tone"` |
| `ios/Offload/Features/Capture/CaptureItemCard.swift` | Add `onTone: () -> Void` callback parameter (matching `onBreakdown`/`onBrainDump`/`onDecisionFatigue` pattern); wire into context menu + accessibility action using `AdvancedAccessibilityActionPolicy.toneActionName` |
| `ios/Offload/Features/Capture/CaptureView.swift` | Add `@State var toneItem: Item?` + `.sheet(item: $toneItem)`; pass `onTone` callback to `ItemCard` |
| `backend/api/src/offload_backend/schemas.py` | Add `ToneTransformRequest`, `ToneTransformResponse` Pydantic models |
| `backend/api/src/offload_backend/main.py` | Include tone router; route decorator `@router.post("/ai/tone/transform")` mounted at `/v1` (matching existing pattern) |
| `backend/api/src/offload_backend/providers/base.py` | Add `ProviderToneResult` dataclass; add `transform_tone()` to `AIProvider` protocol |
| `backend/api/src/offload_backend/providers/openai_adapter.py` | Implement `transform_tone()` |
| `backend/api/src/offload_backend/providers/anthropic_adapter.py` | Implement `transform_tone()` |

---

## Data Model

### `ToneStyle` (Swift enum)

```swift
enum ToneStyle: String, CaseIterable, Identifiable {
    case formal, friendly, concise, empathetic, direct, neutral

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
    var icon: String { /* SF Symbol per tone */ }
    var description: String { /* one-line description */ }
}
```

### `ToneUsage`

```swift
struct ToneUsage: Codable, Equatable {
    let inputTokens: Int
    let outputTokens: Int

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}
```

### `ToneExecutionSource` and `ToneTransformResult`

These internal types are defined in `ToneAssistantService.swift` (not in `AIBackendContracts.swift`), matching the `DecisionFatigueExecutionSource` / `DecisionFatigueExecutionResult` placement in `DecisionFatigueService.swift`.

```swift
enum ToneExecutionSource: Equatable { case onDevice, cloud }

struct ToneTransformResult: Equatable {
    let text: String
    let source: ToneExecutionSource
    let usage: ToneUsage?  // nil for on-device results
}
```

`usage` is optional here because on-device fallback has no token counts. The network `ToneTransformResponse.usage` is non-optional (backend always returns it).

### iOS Codable contracts (in `AIBackendContracts.swift`)

```swift
struct ToneTransformRequest: Codable {
    let inputText: String
    let tone: String
    let contextHints: [String]

    enum CodingKeys: String, CodingKey {
        case inputText = "input_text"
        case tone
        case contextHints = "context_hints"
    }
}

struct ToneTransformResponse: Codable {
    let transformedText: String
    let usage: ToneUsage       // non-optional — backend always returns usage
    let provider: String
    let latencyMs: Int

    enum CodingKeys: String, CodingKey {
        case transformedText = "transformed_text"
        case usage
        case provider
        case latencyMs = "latency_ms"
    }
}
```

### API contract

```
POST /v1/ai/tone/transform
Request:  { input_text: str, tone: str, context_hints: [str] }
Response: { transformed_text: str, provider: str, latency_ms: int,
            usage: { input_tokens: int, output_tokens: int } }
```

`tone` is a plain string (not an enum) for forward compatibility.

---

## Service Layer

### Protocol

```swift
protocol ToneAssistantService {
    func transformTone(inputText: String, tone: ToneStyle) async throws -> ToneTransformResult
    func reconcileUsage(feature: String) async throws -> UsageReconcileResponse?
}
```

### `DefaultToneAssistantService` init

```swift
init(
    backendClient: AIBackendClient,
    consentStore: CloudAIConsentStore,
    usageStore: UsageCounterStore,
    onDeviceTransformer: OnDeviceToneTransforming = SimpleOnDeviceToneTransformer(),
    installIDProvider: @escaping () -> String = {
        UIDevice.current.identifierForVendor?.uuidString ?? "unknown-install"
    }
)
```

Matches `DefaultBreakdownService` / `DefaultDecisionFatigueService` init signatures exactly.

### Cloud path

`DefaultToneAssistantService.transformTone()`:
1. Increments `usageStore` counter for `"tone"`
2. If `consentStore.isCloudAIEnabled`: calls backend, returns `.cloud` result
3. On `AIBackendClientError.shouldFallbackToOnDevice`: falls back to on-device
4. Other errors propagate to the ViewModel

### On-device fallback (`SimpleOnDeviceToneTransformer`)

| Tone | Heuristic |
| --- | --- |
| `formal` | Capitalize first letter, add period, expand contractions (can't→cannot, won't→will not) |
| `concise` | Return first sentence only (split on `.`, `!`, `?`) |
| `friendly` | Append " Hope that helps!" |
| `empathetic` | Prepend "I understand — " |
| `direct` | Strip filler words (just, maybe, perhaps, a bit) |
| `neutral` | Return text unchanged |

Quality is intentionally limited and the source label (`.onDevice`) is surfaced in the UI to nudge cloud opt-in.

---

## Sheet UI

### `ToneAssistantSheetViewModel`

```swift
@Observable @MainActor
final class ToneAssistantSheetViewModel {
    enum Phase { case selectTone, result }

    var phase: Phase = .selectTone
    var selectedTone: ToneStyle?
    var result: ToneTransformResult?
    var isGenerating: Bool = false  // true during async generation; UI shows spinner

    func generate(inputText: String, tone: ToneStyle, using service: ToneAssistantService) async throws
    func reset()  // returns to .selectTone, clears result and selectedTone
}
```

`isGenerating` is the single source of truth for the loading state. `phase` only distinguishes "no result yet" from "result available". Errors are not stored on the ViewModel — they propagate out of `generate()` and are caught by the View, which surfaces them via `ErrorPresenter` (matching the `BreakdownSheet` / `DecisionFatigueSheet` pattern).

### `ToneAssistantSheet` phases

**Phase 1 — Select Tone:**
- Header: "Tone Assistant" + subtitle
- Original capture shown in a muted card
- 2-column grid of 6 tone tiles (icon + name + one-line description)
- Tapping a tile transitions to `.generating`

**Generating state** (`isGenerating == true`, either phase):
- Selected tone tile highlighted with a spinner overlay
- Other tone tiles disabled

**Phase 2 — Result** (`phase == .result`):
- Original capture in a muted card
- Result in an accent-bordered card with tone label + source badge (cloud/on-device)
- Two action buttons: **Copy** (primary, accent fill) and **Save** (secondary, outlined)
- "Try another tone" link → calls `viewModel.reset()`

### Actions

- **Copy**: writes `result.text` to `UIPasteboard.general.string`, triggers light haptic, dismisses sheet
- **Save**: calls `itemRepository.create(type: nil, content: result.text, attachmentData: nil, tags: [], isStarred: false)`, triggers light haptic, posts `.captureItemsChanged`, dismisses sheet

---

## Entry Point

`ItemCard` context menu (in `CaptureItemCard.swift`) — "Rewrite Tone" action (icon: `wand.and.stars`), same placement as "Break Down", "Brain Dump", "Reduce Decision Fatigue". Accessibility action added using `AdvancedAccessibilityActionPolicy.toneActionName`.

`CaptureView` adds:
```swift
@State private var toneItem: Item?
```
and a `.sheet(item: $toneItem)` presenting `ToneAssistantSheet`.

---

## Backend Router (`tone.py`)

```python
POST /v1/ai/tone/transform
- Validates tone string against allowed set
- Constructs system prompt: "Rewrite the following text in a {tone} tone. Return only the rewritten text."
- Calls provider (OpenAI or Anthropic) via existing adapter pattern
- Returns { transformed_text, usage }
```

Follows `decide.py` structure: session token auth, provider selection from `request.app.state`, error handling via existing `errors.py`.

Route decorator: `@router.post("/ai/tone/transform")` — router included in `main.py` at prefix `/v1`, yielding full path `POST /v1/ai/tone/transform`. This matches the `decide.py` / `braindump.py` mounting pattern.

---

## Testing

### iOS unit tests

**`ToneAssistantServiceTests`:**
- Each of 6 tones produces non-empty output via `SimpleOnDeviceToneTransformer`
- `formal` tone expands "can't" → "cannot"
- `concise` tone returns only first sentence
- Cloud path calls backend client with correct tone string
- Network error triggers on-device fallback
- Usage counter incremented on each call

**`ToneAssistantSheetViewModelTests`:**
- `isGenerating` true during generation, false on completion
- Phase transitions: `.selectTone` → `.result` on success
- Error thrown by `generate()` is caught in the View and surfaced via `ErrorPresenter`; `isGenerating` returns to false, phase stays `.selectTone`
- `reset()` clears result, `selectedTone`, and returns phase to `.selectTone`

### Backend tests (`test_tone.py`)

- Valid tone returns 200 with `transformed_text`
- Invalid tone string returns 422
- Provider error returns 502
- Prompt includes tone name and input text

---

## Invariants (from backlog)

- Cloud requires explicit opt-in via `consentStore.isCloudAIEnabled`; fails closed if absent
- Zero content retention (no durable storage of prompts/responses on backend)
- AI suggests, never auto-acts; result is always reviewed before copy/save
- Feature is optional and dismissible
