// Intent: Provide reusable SwiftUI components (buttons, cards, fields, feedback) wired to theme tokens.
//
//  Components.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import SwiftUI

// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.buttonLabelEmphasis)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.md)
                .background(Theme.Gradients.accentPrimary(colorScheme))
                .cornerRadius(Theme.CornerRadius.md)
        }
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.buttonLabelEmphasis)
                .foregroundStyle(Theme.Colors.accentPrimary(colorScheme))
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .stroke(Theme.Colors.accentPrimary(colorScheme), lineWidth: 2)
                )
        }
    }
}

// TODO: Add more button variants (text, icon, floating action, etc.)

// MARK: - Cards

struct CardView<Content: View>: View {
    let content: Content

    @Environment(\.colorScheme) private var colorScheme

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(Theme.Spacing.md)
            .background(Theme.Materials.glass)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(Theme.Materials.glassOverlay(colorScheme))
                    .opacity(Theme.Materials.glassOverlayOpacity)
            )
            .cornerRadius(Theme.CornerRadius.lg)
            .shadow(radius: Theme.Shadows.elevationSm)
    }
}

// TODO: Add more card variants

// MARK: - Input Fields

struct ThemedTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            if !label.isEmpty {
                Text(label)
                    .font(Theme.Typography.inputLabel)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
            }

            TextField(placeholder, text: $text)
                .font(Theme.Typography.body)
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.surface(colorScheme))
                .cornerRadius(Theme.CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .stroke(Theme.Colors.borderMuted(colorScheme), lineWidth: 1)
                )
        }
    }
}

struct ThemedTextEditor: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var minHeight: CGFloat = 100

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            if !label.isEmpty {
                Text(label)
                    .font(Theme.Typography.inputLabel)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
            }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme).opacity(0.5))
                        .padding(Theme.Spacing.sm)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $text)
                    .font(Theme.Typography.body)
                    .frame(minHeight: minHeight)
                    .padding(Theme.Spacing.xs)
                    .scrollContentBackground(.hidden)
                    .background(Theme.Colors.surface(colorScheme))
            }
            .cornerRadius(Theme.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(Theme.Colors.borderMuted(colorScheme), lineWidth: 1)
            )
        }
    }
}

// MARK: - Navigation

// TODO: Add custom NavigationBar component
// TODO: Add TabBar component
// TODO: Add BottomSheet component
// TODO: Add Modal component

// MARK: - Feedback

struct LoadingView: View {
    var message: String = "Loading..."

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Theme.Colors.accentPrimary(colorScheme))

            Text(message)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background(colorScheme))
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)?
    var actionLabel: String?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme))

            VStack(spacing: Theme.Spacing.sm) {
                Text(title)
                    .font(Theme.Typography.title3)
                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme))

                Text(message)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }

            if let action, let label = actionLabel {
                Button(action: action) {
                    Text(label)
                        .font(Theme.Typography.buttonLabel)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Colors.accentPrimary(colorScheme))
                        .cornerRadius(Theme.CornerRadius.md)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background(colorScheme))
    }
}

struct ErrorView: View {
    let error: Error
    var retryAction: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(Theme.Colors.caution(colorScheme))

            VStack(spacing: Theme.Spacing.sm) {
                Text("Something went wrong")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme))

                Text(error.localizedDescription)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }

            if let retry = retryAction {
                Button(action: retry) {
                    Label("Try Again", systemImage: "arrow.clockwise")
                        .font(Theme.Typography.buttonLabel)
                        .foregroundStyle(.white)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Colors.accentPrimary(colorScheme))
                        .cornerRadius(Theme.CornerRadius.md)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background(colorScheme))
    }
}
