// Purpose: Shared utilities and helpers.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Prefer small, reusable helpers and avoid feature-specific coupling.

import Foundation
import Observation
import OSLog


@Observable
@MainActor
final class ErrorPresenter {
    var currentError: PresentableError?

    func present(_ error: Error) {
        AppLogger.general.error("Presenting error to user: \(error.localizedDescription, privacy: .public)")
        currentError = PresentableError(error: error)
    }

    func clear() {
        currentError = nil
    }
}

struct PresentableError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let actions: [ErrorAction]

    init(error: Error) {
        if let validationError = error as? ValidationError {
            title = "Validation Error"
            message = validationError.message
            actions = [.dismiss]
        } else {
            title = "Error"
            message = error.localizedDescription
            actions = [.dismiss, .retry]
        }
    }
}

enum ErrorAction {
    case dismiss
    case retry
    case contact
}

struct ValidationError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        message
    }
}
