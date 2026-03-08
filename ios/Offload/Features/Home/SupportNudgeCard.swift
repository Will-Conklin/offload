// Purpose: Home feature support nudge card — warm, dismissible, message-driven.
// Authority: Code-level
// Governed by: CLAUDE.md

import SwiftUI

/// Displays a warm, non-judgmental support affirmation when the user's uncompleted backlog is large.
/// The card copy is provided by a `SupportNudgeMessage` from the evaluator — swapping to an
/// AI-backed evaluator changes the copy without touching this view.
struct SupportNudgeCard: View {
    let message: SupportNudgeMessage
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        CardSurface(fill: Theme.Colors.cardColor(index: 2, colorScheme, style: style)) {
            HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                Image(systemName: Icons.heart)
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.Colors.accentSecondary(colorScheme, style: style))
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(message.headline)
                        .font(Theme.Typography.cardTitle)
                        .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: style))

                    Text(message.body)
                        .font(Theme.Typography.cardBody)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Button(action: onDismiss) {
                    Image(systemName: Icons.xmark)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Support message: \(message.headline). \(message.body)")
    }
}
