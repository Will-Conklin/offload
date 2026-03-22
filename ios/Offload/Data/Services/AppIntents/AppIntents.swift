// Purpose: App Intent for Siri, Shortcuts, Spotlight, and Action Button capture.
// Authority: Code-level
// Governed by: CLAUDE.md

import AppIntents
import Foundation

// MARK: - OffloadCaptureIntent

/// Captures a thought via Siri, Shortcuts, Spotlight, or the Action Button.
/// Enqueues the capture to PendingCaptureStore; the main app flushes it to SwiftData on next foreground.
@available(iOS 16.0, *)
struct OffloadCaptureIntent: AppIntent {
    static var title: LocalizedStringResource = "Capture a Thought"
    static var description = IntentDescription(
        "Quickly capture a thought, task, or idea into Offload."
    )

    /// The content to capture. Siri prompts for this if not provided.
    @Parameter(title: "Thought", description: "What's on your mind?",
               requestValueDialog: IntentDialog("What would you like to capture?"))
    var content: String

    static var parameterSummary: some ParameterSummary {
        Summary("Offload \(\.$content)")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw OffloadIntentError.emptyContent
        }
        await MainActor.run {
            let capture = PendingCapture(content: trimmed)
            PendingCaptureStore.enqueue(capture)
        }
        return .result(dialog: "Got it — \"\(trimmed)\" captured in Offload.")
    }
}

@available(iOS 16.0, *)
enum OffloadIntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case emptyContent

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .emptyContent:
            "Please say or type something to capture."
        }
    }
}

// MARK: - OffloadShortcutsProvider

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
