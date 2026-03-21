// Purpose: Surfaces the Offload capture intent as a Siri phrase in Shortcuts.
// Authority: Code-level
// Governed by: CLAUDE.md

import AppIntents

/// Registers suggested Siri phrases for the Offload capture intent.
/// Apple requires the app name in the phrase.
@available(iOS 16.0, *)
struct OffloadShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OffloadCaptureIntent(),
            phrases: [
                "Offload something in \(.applicationName)",
                "Offload a thought in \(.applicationName)",
                "Capture a thought in \(.applicationName)",
                "Capture in \(.applicationName)",
            ],
            shortTitle: "Capture a Thought",
            systemImageName: "brain.head.profile"
        )
    }
}
