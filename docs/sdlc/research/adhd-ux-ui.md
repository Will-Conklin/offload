<!-- Intent: Document ADHD-informed UX/UI research and translate it into Offload-specific recommendations. -->

# ADHD-First UX and UI Guidance for Offload

## Research Highlights
- Reduce friction and decision load by offering a single obvious next action at each step; avoid optional fields and cascading choices.
- Favor short, chunked flows with clear progress markers to support working memory and reduce overwhelm.
- Provide predictable layouts and consistent control placement so navigation becomes automatic and less taxing on executive function.
- Use calming, high-contrast-but-not-harsh palettes; limit simultaneous colors to lower visual noise while keeping affordances clear.
- Keep motion subtle and purposeful; abrupt animations or distracting microinteractions can derail focus.
- Pair text with simple icons and microcopy that reassure the user (e.g., “Saved,” “You can organize this later”).
- Offer reversible actions (undo, trash with restore) and gentle reminders instead of punitive alerts to reduce anxiety-driven avoidance.

## Visual and Color Guidance
- **Palette:** Use a muted base (light gray, off-white, or deep charcoal) with one primary accent for focus states and one secondary accent for supportive cues. Reserve bright hues for errors and confirmations to keep urgency signals salient.
- **Contrast:** Maintain accessible contrast for text and controls; prefer medium contrast for secondary elements to avoid clutter. Ensure focus states (selected tabs, active inputs) have strong color and weight cues.
- **Typography:** Choose highly legible, friendly type with generous line spacing. Keep body text 16–18 pt with short line lengths to prevent scanning fatigue.
- **Spacing:** Generous padding and white space reduce cognitive load. Group related elements with consistent spacing tokens to make hierarchy easy to parse.
- **Motion:** Use short, easing animations (<200 ms) only to confirm state changes (save, file, archive). Offer “Reduce Motion” respect via system settings.

## Navigation and Information Architecture
- **Shallow structure:** Keep key areas (Inbox, Capture, Organize, Settings) one tap from the main tab bar. Avoid nested modal stacks; use sheets for capture and full screens for editing.
- **Wayfinding:** Provide persistent headers with context (e.g., “Inbox” plus item counts or filters). Use breadcrumb-like subheaders within Organize to show current list/tag.
- **Capture-first:** A single, always-available capture button (floating or in the tab bar) reduces task-switching friction.
- **Predictable controls:** Place primary actions in consistent locations (trailing toolbar for “Save,” leading for “Close”). Use swipe actions sparingly and always mirror them with visible buttons.
- **Search and filters:** Keep filters minimal (“All,” “Today,” “Tagged”) with plain-language labels. Show active filter chips prominently to avoid hidden state.

## Interaction Patterns
- **One-thing-at-a-time:** Break creation into atomic steps: capture text/voice, then optional tagging/placement later. Show a “Save & close” default path.
- **Progress reassurance:** Use tiny progress indicators or checklists for multi-step flows (e.g., capture → review → file) with the ability to stop after any step.
- **Undo everywhere:** Provide undo snackbars or banners for deletes and moves. Avoid modal confirmations except for destructive batch actions.
- **Defaults and templates:** Offer quick templates (“Idea,” “Task,” “Conversation”) to prefill fields and reduce typing while keeping fields collapsible.
- **Gentle reminders:** Use low-pressure nudges (“Ready to organize 3 notes?”) instead of deadlines. Allow snoozing or dismissing without penalty.
- **Input flexibility:** Support voice and quick text equally. Auto-focus text fields and keep the keyboard available whenever possible.

## Content and Microcopy
- Use short, literal labels (“Capture,” “Send to list,” “Keep in Inbox”).
- Provide reassurance after every save (“Captured. Organize anytime.”).
- Prefer verbs over nouns for buttons to convey action.
- Avoid urgency or alarmist language; emphasize flexibility and reversibility.

## Accessibility Considerations
- Respect Dynamic Type and system accessibility settings (bold text, reduce motion, high contrast).
- Ensure tappable targets are at least 44×44 pt with clear hit areas and generous spacing.
- Offer offline-safe drafts so capture never blocks on connectivity.
- Provide clear focus states for keyboard and switch control users.

## Recommendations for Offload
- **Capture flows (Features/Capture, App/MainTabView):** Keep the capture entry point always visible via a primary tab or floating button. Default to immediate save with optional “Organize now” secondary action; auto-focus the text area and show voice input as an equal first-class option.
- **Inbox (Features/Inbox):** Present items in a calm list with light dividers and concise metadata (timestamp, type). Include batch-select + “Move to…” with undo rather than confirmations. Surface a “Ready to organize” chip when there are unfiled items.
- **Organize (Features/Organize):** Use two-level navigation max: destination list with inline counts, then detail. Provide smart filters (“Recently captured,” “High energy tasks”) as optional chips. Show inline suggestions with opt-in buttons, keeping AI output terse and collapsible.
- **Design system (DesignSystem):** Define tokens for spacing, elevation, and color roles (base, accent, success, caution). Build focus states with both color and stroke weight. Keep iconography simple (stroke weight matching text weight) and pair with labels in navigation.
- **Notifications and reminders (Services/Voice/Notifications):** If reminders are used, make them gentle and deferrable. Offer a daily digest option instead of multiple interrupts.
- **Error handling:** Prefer inline, specific guidance (“Couldn’t save offline. Kept locally; will sync later.”) with retry and undo instead of modal alerts.

## Implementation Priorities (90-day view)
1. Add a persistent capture control and default “capture now, organize later” flow with automatic saving.
2. Introduce undo banners for deletes/moves across Inbox and Organize.
3. Establish color and spacing tokens that emphasize calm hierarchy and accessible focus states.
4. Add gentle organization prompts (chips/cards) instead of blocking modals.
5. Respect system accessibility settings for Dynamic Type and Reduce Motion; audit controls for minimum tap targets.
