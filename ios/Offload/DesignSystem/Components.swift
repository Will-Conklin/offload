// Intent: Provide reusable SwiftUI components (buttons, cards, fields, feedback) wired to theme tokens.
//
//  Components.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import SwiftUI

// AGENT NAV
// - Buttons
// - Cards
// - Input Fields
// - Feedback

// MARK: - Buttons

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
                .shadow(color: Theme.Shadows.ambient(colorScheme), radius: Theme.Shadows.elevationSm, y: 2)
        }
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
                        .stroke(Theme.Colors.accentPrimary(colorScheme, style: themeManager.currentStyle).opacity(0.7), lineWidth: 1.5)
                )
        }
    }
}

struct TextButton: View {
    let title: String
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.buttonLabelEmphasis)
                .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: themeManager.currentStyle))
                .padding(.vertical, Theme.Spacing.sm)
                .padding(.horizontal, Theme.Spacing.sm)
        }
        .buttonStyle(.plain)
    }
}

struct IconButton: View {
    enum Style {
        case plain
        case filled
        case outline
    }

    let iconName: String
    let accessibilityLabel: String
    let style: Style
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            AppIcon(name: iconName, size: 16)
                .foregroundStyle(iconForeground)
                .frame(width: Theme.HitTarget.minimum.width, height: Theme.HitTarget.minimum.height)
                .background(iconBackground)
                .overlay(iconBorder)
                .clipShape(Circle())
        }
        .accessibilityLabel(accessibilityLabel)
        .buttonStyle(.plain)
    }

    private var iconForeground: Color {
        switch style {
        case .plain, .outline:
            return Theme.Colors.accentPrimary(colorScheme, style: themeManager.currentStyle)
        case .filled:
            return .white
        }
    }

    @ViewBuilder
    private var iconBackground: some View {
        switch style {
        case .plain, .outline:
            Color.clear
        case .filled:
            Theme.Colors.accentPrimary(colorScheme, style: themeManager.currentStyle)
        }
    }

    @ViewBuilder
    private var iconBorder: some View {
        switch style {
        case .outline:
            Circle()
                .stroke(Theme.Colors.borderMuted(colorScheme, style: themeManager.currentStyle), lineWidth: 1)
        default:
            EmptyView()
        }
    }
}

struct FloatingActionButton: View {
    let title: String
    let iconName: String
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            Label {
                Text(title)
            } icon: {
                AppIcon(name: iconName, size: 14)
            }
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(.white)
                .padding(.vertical, Theme.Spacing.sm)
                .padding(.horizontal, Theme.Spacing.md)
                .background(
                    Capsule()
                        .fill(Theme.Gradients.accentPrimary(colorScheme, style: themeManager.currentStyle))
                )
                .shadow(color: Theme.Shadows.ambient(colorScheme), radius: Theme.Shadows.elevationMd, y: 4)
        }
    }
}

// MARK: - Cards

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? Theme.Cards.pressScale : 1)
            .animation(Theme.Animations.easeInOutShort, value: configuration.isPressed)
    }
}

extension View {
    func cardButtonStyle() -> some View {
        buttonStyle(CardButtonStyle())
    }
}

struct CardView<Content: View>: View {
    let content: Content

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.md)
            .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: themeManager.currentStyle))
            .background(Theme.Colors.cardBackground(colorScheme, style: themeManager.currentStyle))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .stroke(Theme.Colors.borderMuted(colorScheme, style: themeManager.currentStyle).opacity(0.5), lineWidth: 1)
            )
            .cornerRadius(Theme.CornerRadius.lg)
            .shadow(color: Theme.Shadows.ambient(colorScheme), radius: Theme.Shadows.elevationSm, y: 2)
    }
}

struct ElevatedCardView<Content: View>: View {
    let content: Content

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.lg)
            .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: themeManager.currentStyle))
            .background(Theme.Colors.cardBackground(colorScheme, style: themeManager.currentStyle))
            .cornerRadius(Theme.CornerRadius.xl)
            .shadow(color: Theme.Shadows.ambient(colorScheme), radius: Theme.Shadows.elevationMd, y: 6)
    }
}

struct OutlineCardView<Content: View>: View {
    let content: Content

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.md)
            .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: themeManager.currentStyle))
            .background(Theme.Colors.cardBackground(colorScheme, style: themeManager.currentStyle))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .stroke(Theme.Colors.borderMuted(colorScheme, style: themeManager.currentStyle).opacity(0.6), lineWidth: 1)
            )
            .cornerRadius(Theme.CornerRadius.lg)
    }
}

struct SelectableCardView<Content: View>: View {
    let isSelected: Bool
    let onTap: (() -> Void)?
    let content: Content

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    init(isSelected: Bool, onTap: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.isSelected = isSelected
        self.onTap = onTap
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.md)
            .foregroundStyle(Theme.Colors.cardTextPrimary(colorScheme, style: themeManager.currentStyle))
            .background(Theme.Colors.cardBackground(colorScheme, style: themeManager.currentStyle))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(Theme.CornerRadius.lg)
            .shadow(color: Theme.Shadows.ambient(colorScheme), radius: Theme.Shadows.elevationSm, y: 2)
            .onTapGesture {
                onTap?()
            }
    }

    private var borderColor: Color {
        isSelected
            ? Theme.Colors.accentPrimary(colorScheme, style: themeManager.currentStyle)
            : Theme.Colors.borderMuted(colorScheme, style: themeManager.currentStyle).opacity(0.6)
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
                        .stroke(Theme.Colors.borderMuted(colorScheme, style: themeManager.currentStyle).opacity(0.6), lineWidth: 0.8)
                )
                .shadow(color: Theme.Shadows.ambient(colorScheme), radius: Theme.Shadows.elevationXs, y: 1)
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
                    .stroke(Theme.Colors.borderMuted(colorScheme, style: themeManager.currentStyle).opacity(0.6), lineWidth: 0.8)
            )
            .shadow(color: Theme.Shadows.ambient(colorScheme), radius: Theme.Shadows.elevationXs, y: 1)
        }
    }
}

// MARK: - Navigation

struct ThemedNavigationBar<Leading: View, Trailing: View>: View {
    let title: String
    let subtitle: String?
    let leading: Leading
    let trailing: Trailing

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder leading: () -> Leading = { EmptyView() },
        @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leading = leading()
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.md) {
            leading
                .frame(minWidth: Theme.HitTarget.minimum.width, minHeight: Theme.HitTarget.minimum.height, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Typography.title3)
                    .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: themeManager.currentStyle))

                if let subtitle {
                    Text(subtitle)
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: themeManager.currentStyle))
                }
            }

            Spacer()

            trailing
                .frame(minWidth: Theme.HitTarget.minimum.width, minHeight: Theme.HitTarget.minimum.height, alignment: .trailing)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colors.background(colorScheme, style: themeManager.currentStyle))
    }
}

struct TabBarItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let iconName: String
}

struct ThemedTabBar: View {
    let items: [TabBarItem]
    @Binding var selectedIndex: Int

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Button {
                    selectedIndex = index
                } label: {
                    VStack(spacing: 4) {
                        AppIcon(name: item.iconName, size: 16)
                        Text(item.title)
                            .font(.caption)
                    }
                    .foregroundStyle(foregroundColor(for: index))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(background(for: index))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.xl)
                .fill(Theme.Colors.surface(colorScheme, style: themeManager.currentStyle))
                .shadow(color: Theme.Shadows.ambient(colorScheme), radius: Theme.Shadows.elevationSm, y: 2)
        )
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private func foregroundColor(for index: Int) -> Color {
        selectedIndex == index
            ? Theme.Colors.accentPrimary(colorScheme, style: themeManager.currentStyle)
            : Theme.Colors.textSecondary(colorScheme, style: themeManager.currentStyle)
    }

    @ViewBuilder
    private func background(for index: Int) -> some View {
        if selectedIndex == index {
            Theme.Colors.accentPrimary(colorScheme, style: themeManager.currentStyle)
                .opacity(colorScheme == .dark ? 0.18 : 0.12)
        } else {
            Color.clear
        }
    }
}

struct BottomSheet<Content: View>: View {
    @Binding var isPresented: Bool
    let title: String?
    let content: Content

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    init(isPresented: Binding<Bool>, title: String? = nil, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.title = title
        self.content = content()
    }

    var body: some View {
        if isPresented {
            ZStack(alignment: .bottom) {
                Color.black.opacity(colorScheme == .dark ? 0.45 : 0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented = false
                    }

                VStack(spacing: Theme.Spacing.md) {
                    Capsule()
                        .fill(Theme.Colors.borderMuted(colorScheme, style: themeManager.currentStyle))
                        .frame(width: 40, height: 5)

                    if let title {
                        Text(title)
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: themeManager.currentStyle))
                    }

                    content
                }
                .padding(Theme.Spacing.lg)
                .frame(maxWidth: .infinity)
                .background(Theme.Colors.surface(colorScheme, style: themeManager.currentStyle))
                .cornerRadius(Theme.CornerRadius.xl)
                .shadow(color: Theme.Shadows.ambient(colorScheme), radius: Theme.Shadows.elevationMd, y: 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .animation(Theme.Animations.easeInOutShort, value: isPresented)
        }
    }
}

struct ModalCard<Content: View>: View {
    @Binding var isPresented: Bool
    let title: String
    let content: Content

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    init(isPresented: Binding<Bool>, title: String, @ViewBuilder content: () -> Content) {
        self._isPresented = isPresented
        self.title = title
        self.content = content()
    }

    var body: some View {
        if isPresented {
            ZStack {
                Color.black.opacity(colorScheme == .dark ? 0.45 : 0.25)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented = false
                    }

                VStack(spacing: Theme.Spacing.md) {
                    Text(title)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textPrimary(colorScheme, style: themeManager.currentStyle))

                    content

                    Button("Close") {
                        isPresented = false
                    }
                    .font(Theme.Typography.buttonLabelEmphasis)
                    .foregroundStyle(Theme.Colors.accentPrimary(colorScheme, style: themeManager.currentStyle))
                }
                .padding(Theme.Spacing.lg)
                .frame(maxWidth: 360)
                .background(Theme.Colors.surface(colorScheme, style: themeManager.currentStyle))
                .cornerRadius(Theme.CornerRadius.xl)
                .shadow(color: Theme.Shadows.ambient(colorScheme), radius: Theme.Shadows.elevationMd, y: 8)
                .transition(.scale.combined(with: .opacity))
            }
            .animation(Theme.Animations.easeInOutShort, value: isPresented)
        }
    }
}

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
            AppIcon(name: icon, size: 60)
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

struct ErrorView: View {
    let error: Error
    var retryAction: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            AppIcon(name: Icons.warningFilled, size: 50)
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
                    Label {
                        Text("Try Again")
                    } icon: {
                        AppIcon(name: Icons.refresh, size: 14)
                    }
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

// MARK: - Previews

#Preview("Buttons") {
    VStack(spacing: Theme.Spacing.md) {
        PrimaryButton(title: "Primary") {}
        SecondaryButton(title: "Secondary") {}
        TextButton(title: "Text Button") {}
        HStack(spacing: Theme.Spacing.md) {
            IconButton(iconName: Icons.add, accessibilityLabel: "Add", style: .plain) {}
            IconButton(iconName: Icons.heartFilled, accessibilityLabel: "Favorite", style: .filled) {}
            IconButton(iconName: Icons.settings, accessibilityLabel: "Settings", style: .outline) {}
        }
        FloatingActionButton(title: "Capture", iconName: Icons.microphoneFilled) {}
    }
    .padding(Theme.Spacing.lg)
    .background(Theme.Colors.background(.light, style: .violetPop))
    .environmentObject(ThemeManager.shared)
}

#Preview("Cards") {
    VStack(spacing: Theme.Spacing.lg) {
        CardView {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Card Title")
                    .font(Theme.Typography.cardTitle)
                Text("A quick summary of the content inside this card.")
                    .font(Theme.Typography.cardBody)
                    .foregroundStyle(Theme.Colors.cardTextSecondary(.light, style: .oceanTeal))
            }
        }

        ElevatedCardView {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Elevated Card")
                    .font(Theme.Typography.cardTitle)
                Text("Softer shadows and more generous padding.")
                    .font(Theme.Typography.cardBody)
                    .foregroundStyle(Theme.Colors.cardTextSecondary(.light, style: .oceanTeal))
            }
        }

        OutlineCardView {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Outline Card")
                    .font(Theme.Typography.cardTitle)
                Text("Minimal border, flat surface.")
                    .font(Theme.Typography.cardBody)
                    .foregroundStyle(Theme.Colors.cardTextSecondary(.light, style: .oceanTeal))
            }
        }

        SelectableCardView(isSelected: true) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Selectable Card")
                    .font(Theme.Typography.cardTitle)
                Text("Selected state uses accent border.")
                    .font(Theme.Typography.cardBody)
                    .foregroundStyle(Theme.Colors.cardTextSecondary(.light, style: .oceanTeal))
            }
        }
    }
    .padding(Theme.Spacing.lg)
    .background(Theme.Colors.background(.light, style: .oceanTeal))
    .environmentObject(ThemeManager.shared)
}

#Preview("Navigation") {
    VStack(spacing: Theme.Spacing.lg) {
        ThemedNavigationBar(
            title: "Captures",
            subtitle: "Today",
            leading: {
                IconButton(iconName: Icons.back, accessibilityLabel: "Back", style: .plain) {}
            },
            trailing: {
                IconButton(iconName: Icons.add, accessibilityLabel: "Add", style: .filled) {}
            }
        )

        Spacer()

        ThemedTabBar(
            items: [
                TabBarItem(title: "Captures", iconName: Icons.inbox),
                TabBarItem(title: "Organize", iconName: Icons.category),
                TabBarItem(title: "Settings", iconName: Icons.settings)
            ],
            selectedIndex: .constant(0)
        )
    }
    .padding(.vertical, Theme.Spacing.lg)
    .background(Theme.Colors.background(.light, style: .oceanTeal))
    .environmentObject(ThemeManager.shared)
}

#Preview("Overlays") {
    ZStack {
        Theme.Gradients.appBackground(.light, style: .violetPop)
            .ignoresSafeArea()

        BottomSheet(isPresented: .constant(true), title: "Quick Actions") {
            VStack(spacing: Theme.Spacing.sm) {
                Text("Add a capture, plan, or list.")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.cardTextSecondary(.light, style: .violetPop))
                PrimaryButton(title: "New Capture") {}
            }
        }

        ModalCard(isPresented: .constant(true), title: "Focus Mode") {
            Text("Reduce distractions and capture fast.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Colors.cardTextSecondary(.light, style: .violetPop))
        }
    }
    .environmentObject(ThemeManager.shared)
}
