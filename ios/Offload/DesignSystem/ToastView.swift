// Purpose: Design system components and theme definitions.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Preserve established theme defaults and component APIs.

//  (success, error, info, warning messages) with auto-dismissal.

import SwiftUI

// MARK: - Toast Type

enum ToastType {
    case success
    case error
    case info
    case warning

    var iconName: String {
        switch self {
        case .success: Icons.checkCircleFilled
        case .error: Icons.closeCircleFilled
        case .info: Icons.infoCircleFilled
        case .warning: Icons.warningFilled
        }
    }

    func color(_ colorScheme: ColorScheme, style: ThemeStyle = .midCenturyModern) -> Color {
        switch self {
        case .success: Theme.Colors.success(colorScheme, style: style)
        case .error: Theme.Colors.destructive(colorScheme, style: style)
        case .info: Theme.Colors.accentPrimary(colorScheme, style: style)
        case .warning: Theme.Colors.caution(colorScheme, style: style)
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
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            AppIcon(name: toast.type.iconName, size: 18)
                .foregroundStyle(toast.type.color(colorScheme, style: themeManager.currentStyle))
                .accessibilityHidden(true)

            Text(toast.message)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: themeManager.currentStyle))
                .lineLimit(3)

            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Surface.card(colorScheme, style: themeManager.currentStyle))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.cardSoft, style: .continuous))
        .shadow(
            color: Theme.Shadows.ultraLight(colorScheme),
            radius: Theme.Shadows.elevationUltraLight,
            y: Theme.Shadows.offsetYUltraLight
        )
        .padding(.horizontal, Theme.Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(toast.message)
        .accessibilityHint("Double tap to dismiss.")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Toast Manager

@Observable
@MainActor
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
                try _Concurrency.Task.checkCancellation()
                currentToast = nil
            } catch is CancellationError {
                return
            } catch {
                currentToast = nil
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
    .environmentObject(ThemeManager.shared)
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
    .environmentObject(ThemeManager.shared)
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
    .environmentObject(ThemeManager.shared)
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
    .environmentObject(ThemeManager.shared)
}
