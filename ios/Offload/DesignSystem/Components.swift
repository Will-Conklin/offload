// Intent: Provide reusable SwiftUI components (buttons, cards, fields, feedback) wired to theme tokens.
//
//  Components.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import SwiftUI

// MARK: - Buttons

struct PressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.96 : 1))
            .animation(reduceMotion ? nil : Theme.Animations.springDefault, value: configuration.isPressed)
    }
}

enum BadgeStyle {
    case accent
    case success
    case warning
    case neutral

    func foregroundColor(_ colorScheme: ColorScheme) -> Color {
        switch self {
        case .accent:
            Theme.Colors.accentPrimary(colorScheme)
        case .success:
            Theme.Colors.success(colorScheme)
        case .warning:
            Theme.Colors.caution(colorScheme)
        case .neutral:
            Theme.Colors.textSecondary(colorScheme)
        }
    }

    func backgroundColor(_ colorScheme: ColorScheme) -> Color {
        switch self {
        case .accent:
            Theme.Colors.accentPrimary(colorScheme).opacity(0.2)
        case .success:
            Theme.Colors.success(colorScheme).opacity(0.2)
        case .warning:
            Theme.Colors.caution(colorScheme).opacity(0.2)
        case .neutral:
            Theme.Colors.surface(colorScheme)
        }
    }
}

struct Badge: View {
    let text: String
    var icon: String?
    var style: BadgeStyle = .accent

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(Theme.Typography.badge)
            }

            Text(text)
                .font(Theme.Typography.badge)
        }
        .foregroundStyle(style.foregroundColor(colorScheme))
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(style.backgroundColor(colorScheme))
        .cornerRadius(Theme.CornerRadius.sm)
        .accessibilityLabel("\(text) badge")
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.buttonLabelEmphasis)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.md)
                .background(Theme.Gradients.accentPrimary(colorScheme, style: themeManager.currentStyle))
                .cornerRadius(Theme.CornerRadius.md)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.buttonLabelEmphasis)
                .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: themeManager.currentStyle))
                .frame(maxWidth: .infinity)
                .padding(Theme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .stroke(Theme.Colors.accentPrimary(colorScheme, style: themeManager.currentStyle), lineWidth: 2)
                )
        }
        .buttonStyle(PressableButtonStyle())
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
            .shadow(
                color: Theme.Shadows.cardShadow(colorScheme),
                radius: Theme.Shadows.elevationMd,
                x: 0,
                y: Theme.Shadows.elevationSm
            )
    }
}

struct ExpandableCard<Header: View>: View {
    let header: Header
    let bodyText: String
    var collapsedLineLimit: Int = 2
    var accessibilityLabel: String = "Expandable card"

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isExpanded = false

    init(
        bodyText: String,
        collapsedLineLimit: Int = 2,
        accessibilityLabel: String = "Expandable card",
        @ViewBuilder header: () -> Header
    ) {
        self.header = header()
        self.bodyText = bodyText
        self.collapsedLineLimit = collapsedLineLimit
        self.accessibilityLabel = accessibilityLabel
    }

    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                header

                Text(bodyText)
                    .font(Theme.Typography.cardBody)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme))
                    .lineLimit(isExpanded ? nil : collapsedLineLimit)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if reduceMotion {
                isExpanded.toggle()
            } else {
                withAnimation(Theme.Animations.springDefault) {
                    isExpanded.toggle()
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        .accessibilityHint(isExpanded ? "Double-tap to collapse" : "Double-tap to expand")
    }
}

// TODO: Add more card variants

// MARK: - Filters

struct PillSelector: View {
    let title: String
    let options: [String]
    @Binding var selection: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title)
                .font(Theme.Typography.inputLabel)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            withAnimation(Theme.Animations.springDefault) {
                                selection = option
                            }
                        } label: {
                            Text(option)
                                .font(Theme.Typography.badgeEmphasis)
                                .foregroundStyle(textColor(for: option))
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.vertical, Theme.Spacing.xs)
                                .background(backgroundColor(for: option))
                                .cornerRadius(Theme.CornerRadius.lg)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(title) option \(option)")
                        .accessibilityValue(option == selection ? "Selected" : "Not selected")
                        .accessibilityHint("Double-tap to select")
                    }
                }
                .padding(.vertical, Theme.Spacing.xs)
            }
        }
    }

    private func textColor(for option: String) -> Color {
        option == selection
            ? Theme.Colors.textPrimary(colorScheme)
            : Theme.Colors.textSecondary(colorScheme)
    }

    private func backgroundColor(for option: String) -> Color {
        option == selection
            ? Theme.Colors.accentPrimary(colorScheme).opacity(0.2)
            : Theme.Colors.surface(colorScheme)
    }
}

// MARK: - Input Fields

struct ThemedTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            if !label.isEmpty {
                Text(label)
                    .font(Theme.Typography.inputLabel)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: themeManager.currentStyle))
            }

            TextField(placeholder, text: $text)
                .font(Theme.Typography.body)
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.surface(colorScheme, style: themeManager.currentStyle))
                .cornerRadius(Theme.CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                        .stroke(Theme.Colors.borderMuted(colorScheme, style: themeManager.currentStyle), lineWidth: 1)
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
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            if !label.isEmpty {
                Text(label)
                    .font(Theme.Typography.inputLabel)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: themeManager.currentStyle))
            }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: themeManager.currentStyle).opacity(0.5))
                        .padding(Theme.Spacing.sm)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $text)
                    .font(Theme.Typography.body)
                    .frame(minHeight: minHeight)
                    .padding(Theme.Spacing.xs)
                    .scrollContentBackground(.hidden)
                    .background(Theme.Colors.surface(colorScheme, style: themeManager.currentStyle))
            }
            .cornerRadius(Theme.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                    .stroke(Theme.Colors.borderMuted(colorScheme, style: themeManager.currentStyle), lineWidth: 1)
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
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Theme.Colors.accentPrimary(colorScheme, style: themeManager.currentStyle))

            Text(message)
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: themeManager.currentStyle))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background(colorScheme, style: themeManager.currentStyle))
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var action: (() -> Void)?
    var actionLabel: String?

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: themeManager.currentStyle))

            VStack(spacing: Theme.Spacing.sm) {
                Text(title)
                    .font(Theme.Typography.title3)
                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: themeManager.currentStyle))

                Text(message)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: themeManager.currentStyle))
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
                        .background(Theme.Colors.accentPrimary(colorScheme, style: themeManager.currentStyle))
                        .cornerRadius(Theme.CornerRadius.md)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background(colorScheme, style: themeManager.currentStyle))
    }
}

// MARK: - Progress Indicators

struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 8
    var size: CGFloat = 44

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.Colors.borderMuted(colorScheme), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: max(0, min(progress, 1)))
                .stroke(
                    Theme.Colors.accentPrimary(colorScheme),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(max(0, min(progress, 1)) * 100)) percent")
    }
}

struct ProgressBar: View {
    let progress: Double
    var height: CGFloat = 8

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.Colors.borderMuted(colorScheme))
                    .frame(height: height)

                Capsule()
                    .fill(Theme.Colors.accentPrimary(colorScheme))
                    .frame(width: proxy.size.width * max(0, min(progress, 1)), height: height)
            }
        }
        .frame(height: height)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(max(0, min(progress, 1)) * 100)) percent")
    }
}

struct SkeletonView: View {
    var cornerRadius: CGFloat = Theme.CornerRadius.md
    var width: CGFloat?
    var height: CGFloat = 16

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -0.6

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Theme.Colors.surface(colorScheme))
            .overlay {
                GeometryReader { proxy in
                    let gradient = LinearGradient(
                        colors: [
                            Theme.Colors.surface(colorScheme).opacity(0.6),
                            Theme.Colors.borderMuted(colorScheme).opacity(0.8),
                            Theme.Colors.surface(colorScheme).opacity(0.6),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Rectangle()
                        .fill(gradient)
                        .rotationEffect(.degrees(20))
                        .offset(x: proxy.size.width * phase)
                }
                .clipped()
            }
            .frame(width: width, height: height)
            .accessibilityLabel("Loading")
            .onAppear {
                if reduceMotion {
                    phase = 0
                } else {
                    withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                        phase = 0.6
                    }
                }
            }
    }
}

struct ErrorView: View {
    let error: Error
    var retryAction: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(Theme.Colors.caution(colorScheme, style: themeManager.currentStyle))

            VStack(spacing: Theme.Spacing.sm) {
                Text("Something went wrong")
                    .font(Theme.Typography.headline)
                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: themeManager.currentStyle))

                Text(error.localizedDescription)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: themeManager.currentStyle))
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
                        .background(Theme.Colors.accentPrimary(colorScheme, style: themeManager.currentStyle))
                        .cornerRadius(Theme.CornerRadius.md)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background(colorScheme, style: themeManager.currentStyle))
    }
}
