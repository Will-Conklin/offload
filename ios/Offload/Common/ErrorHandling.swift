//
//  ErrorHandling.swift
//  Offload
//
//  Created by Claude Code on 1/7/26.
//
//  Intent: Centralized error presentation types for consistent user-facing alerts
//  and retry messaging across the app.
//

import Foundation
import Observation

// AGENT NAV
// - Presenter
// - Presentable Error
// - Actions
// - Validation Errors

@Observable
@MainActor
final class ErrorPresenter {
    var currentError: PresentableError?

    func present(_ error: Error) {
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
