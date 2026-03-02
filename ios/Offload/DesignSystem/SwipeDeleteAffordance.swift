// Purpose: Reusable swipe affordance views for leading and trailing swipe actions.
// Authority: Code-level
// Governed by: AGENTS.md

import SwiftUI

/// A reusable swipe affordance rendered behind a card on either the leading or trailing side.
struct SwipeAffordance: View {
    enum Side {
        case leading, trailing
    }

    let side: Side
    let iconName: String
    let color: Color
    let progress: Double
    let isEnabled: Bool
    let accessibilityLabel: String
    let accessibilityHint: String
    let action: () -> Void

    var body: some View {
        HStack {
            if side == .trailing { Spacer() }

            Button(action: action) {
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md, style: .continuous)
                    .fill(color.opacity(0.14))
                    .overlay {
                        AppIcon(name: iconName, size: 18)
                            .foregroundStyle(color)
                    }
                    .frame(
                        width: Theme.Spacing.xl + Theme.Spacing.lg,
                        height: Theme.HitTarget.minimum.height + Theme.Spacing.sm
                    )
                    .scaleEffect(0.9 + (0.1 * progress))
            }
            .buttonStyle(.plain)
            .padding(side == .leading ? .leading : .trailing, Theme.Spacing.sm)
            .opacity(progress)
            .disabled(!isEnabled)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(accessibilityHint)

            if side == .leading { Spacer() }
        }
    }
}
