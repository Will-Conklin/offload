// Purpose: Reusable trailing-gutter delete affordance for swipe interactions.
// Authority: Code-level
// Governed by: AGENTS.md

import SwiftUI

struct TrailingDeleteAffordance: View {
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let progress: Double
    let isEnabled: Bool
    let accessibilityLabel: String
    let accessibilityHint: String
    let action: () -> Void

    var body: some View {
        HStack {
            Spacer()

            Button(action: action) {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                    .fill(Theme.Colors.destructive(colorScheme, style: style).opacity(0.14))
                    .overlay {
                        AppIcon(name: Icons.deleteFilled, size: 18)
                            .foregroundStyle(Theme.Colors.destructive(colorScheme, style: style))
                    }
                    .frame(
                        width: Theme.Spacing.xl + Theme.Spacing.lg,
                        height: Theme.HitTarget.minimum.height + Theme.Spacing.sm
                    )
                    .scaleEffect(0.9 + (0.1 * progress))
            }
            .buttonStyle(.plain)
            .padding(.trailing, Theme.Spacing.sm)
            .opacity(progress)
            .disabled(!isEnabled)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(accessibilityHint)
        }
    }
}
