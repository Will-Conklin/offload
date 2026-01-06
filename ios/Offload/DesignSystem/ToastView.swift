//
//  ToastView.swift
//  Offload
//
//  Created by Claude Code on 1/5/26.
//
//  Intent: Toast notification system for displaying transient user feedback
//  (success, error, info, warning messages) with auto-dismissal.
//

import SwiftUI

// MARK: - Toast Type

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

// MARK: - Toast Model

struct Toast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let type: ToastType

    static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Toast View

struct ToastView: View {
    let toast: Toast

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: toast.type.icon)
                .foregroundStyle(toast.type.color(colorScheme))
                .font(Theme.Typography.headline)

            Text(toast.message)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textPrimary(colorScheme))
                .lineLimit(3)

            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surface(colorScheme))
        .cornerRadius(Theme.CornerRadius.lg)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .padding(.horizontal, Theme.Spacing.md)
    }
}

// MARK: - Toast Manager

@Observable
class ToastManager {
    var currentToast: Toast?
    private var dismissTask: _Concurrency.Task<Void, Never>?

    func show(_ message: String, type: ToastType, duration: TimeInterval = 3.0) {
        // Cancel any existing dismiss task
        dismissTask?.cancel()

        // Show new toast
        currentToast = Toast(message: message, type: type)

        // Auto-dismiss after duration
        dismissTask = _Concurrency.Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                try await _Concurrency.Task.sleep(for: .seconds(duration))
                self.currentToast = nil
            } catch is CancellationError {
                // Expected when showing new toast before previous dismisses
            }
        }
    }

    func dismiss() {
        dismissTask?.cancel()
        currentToast = nil
    }
}

// MARK: - View Modifier

struct ToastModifier: ViewModifier {
    @State private var toastManager = ToastManager()

    func body(content: Content) -> some View {
        content
            .environment(toastManager)
            .overlay(alignment: .top) {
                if let toast = toastManager.currentToast {
                    ToastView(toast: toast)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: toastManager.currentToast)
                        .padding(.top, Theme.Spacing.md)
                        .onTapGesture {
                            toastManager.dismiss()
                        }
                }
            }
    }
}

// MARK: - View Extension

extension View {
    /// Adds toast notification support to the view
    func withToast() -> some View {
        modifier(ToastModifier())
    }
}

// MARK: - Previews

#Preview("Success Toast") {
    VStack {
        Text("Content")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemBackground))
    .overlay(alignment: .top) {
        ToastView(toast: Toast(message: "Item saved successfully!", type: .success))
            .padding(.top, 16)
    }
}

#Preview("Error Toast") {
    VStack {
        Text("Content")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemBackground))
    .overlay(alignment: .top) {
        ToastView(toast: Toast(message: "Failed to save item. Please try again.", type: .error))
            .padding(.top, 16)
    }
}

#Preview("Warning Toast") {
    VStack {
        Text("Content")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemBackground))
    .overlay(alignment: .top) {
        ToastView(toast: Toast(message: "Network connection is unstable.", type: .warning))
            .padding(.top, 16)
    }
}

#Preview("Info Toast") {
    VStack {
        Text("Content")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(.systemBackground))
    .overlay(alignment: .top) {
        ToastView(toast: Toast(message: "AI suggestions are currently disabled.", type: .info))
            .padding(.top, 16)
    }
}
