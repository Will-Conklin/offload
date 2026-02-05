// Purpose: Error presentation helpers for SwiftUI views.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep error presentation lightweight and reusable.

import Observation
import SwiftUI

struct ErrorToastModifier: ViewModifier {
    @Bindable var presenter: ErrorPresenter
    @Environment(ToastManager.self) private var toastManager

    func body(content: Content) -> some View {
        content
            .onChange(of: presenter.currentError?.id) { _, _ in
                guard let error = presenter.currentError else { return }
                let message = error.title == "Error"
                    ? error.message
                    : "\(error.title): \(error.message)"
                let toastType: ToastType = error.title == "Validation Error" ? .warning : .error
                toastManager.show(message, type: toastType)
                presenter.clear()
            }
    }
}

extension View {
    func errorToasts(_ presenter: ErrorPresenter) -> some View {
        modifier(ErrorToastModifier(presenter: presenter))
    }
}
