// Purpose: App entry points and root navigation.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep navigation flow consistent with MainTabView -> NavigationStack -> sheets.

//  Flat design with floating pill tab bar

import SwiftUI
import SwiftData


struct MainTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedTab: Tab = .review
    @State private var quickCaptureMode: CaptureComposeMode?

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        TabContent(selectedTab: selectedTab)
            .safeAreaInset(edge: .bottom) {
                FloatingTabBar(
                    selectedTab: $selectedTab,
                    colorScheme: colorScheme,
                    style: style,
                    onQuickWrite: { quickCaptureMode = .write },
                    onQuickVoice: { quickCaptureMode = .voice }
                )
                .padding(.horizontal, 0)
            }
            .sheet(item: $quickCaptureMode) { mode in
                CaptureComposeView(mode: mode)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
    }

    enum Tab: CaseIterable {
        case home
        case review
        case organize
        case account

        var icon: String {
            switch self {
            case .home: return Icons.home
            case .review: return Icons.review
            case .organize: return Icons.organize
            case .account: return Icons.account
            }
        }

        var selectedIcon: String {
            switch self {
            case .home: return Icons.homeSelected
            case .review: return Icons.reviewSelected
            case .organize: return Icons.organizeSelected
            case .account: return Icons.accountSelected
            }
        }

        var label: String {
            switch self {
            case .home: return "Home"
            case .review: return "Review"
            case .organize: return "Organize"
            case .account: return "Account"
            }
        }
    }
}

// MARK: - Tab Content

private struct TabContent: View {
    let selectedTab: MainTabView.Tab

    var body: some View {
        switch selectedTab {
        case .home:
            HomeView()
        case .review:
            CaptureView(navigationTitle: "Review")
        case .organize:
            OrganizeView()
        case .account:
            AccountView()
        }
    }
}

// MARK: - Floating Tab Bar

private struct FloatingTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onQuickWrite: () -> Void
    let onQuickVoice: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            TabSlot {
                TabButton(
                    tab: .home,
                    isSelected: selectedTab == .home,
                    colorScheme: colorScheme,
                    style: style
                ) { selectedTab = .home }
            }

            TabSlot {
                TabButton(
                    tab: .review,
                    isSelected: selectedTab == .review,
                    colorScheme: colorScheme,
                    style: style
                ) { selectedTab = .review }
            }

            TabSlot {
                OffloadCTA(
                    colorScheme: colorScheme,
                    style: style,
                    onQuickWrite: onQuickWrite,
                    onQuickVoice: onQuickVoice
                )
            }

            TabSlot {
                TabButton(
                    tab: .organize,
                    isSelected: selectedTab == .organize,
                    colorScheme: colorScheme,
                    style: style
                ) { selectedTab = .organize }
            }

            TabSlot {
                TabButton(
                    tab: .account,
                    isSelected: selectedTab == .account,
                    colorScheme: colorScheme,
                    style: style
                ) { selectedTab = .account }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 0)
        .background(
            Capsule()
                .fill(Theme.Colors.surface(colorScheme, style: style))
                .overlay(
                    Capsule()
                        .stroke(Theme.Colors.primary(colorScheme, style: style).opacity(0.35), lineWidth: 1)
                )
                .shadow(color: Theme.Shadows.ultraLight(colorScheme), radius: Theme.Shadows.elevationUltraLight, y: Theme.Shadows.offsetYUltraLight)
        )
    }
}

private struct TabSlot<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content.frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Offload CTA

private struct OffloadCTA: View {
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onQuickWrite: () -> Void
    let onQuickVoice: () -> Void
    @State private var isExpanded = false
    @State private var quickActionBounce: CGFloat = 0

    private let mainButtonSize: CGFloat = 64
    private let quickActionLift: CGFloat = 64
    private var slotWidth: CGFloat { mainButtonSize + 12 }
    private var mainButtonYOffset: CGFloat { -Theme.Spacing.xl }
    private var quickActionYOffset: CGFloat { mainButtonYOffset - quickActionLift }

    private var expansionAnimation: Animation {
        .spring(response: 0.4, dampingFraction: 0.6)
    }

    var body: some View {
        ZStack {
            OffloadMainButton(
                colorScheme: colorScheme,
                style: style,
                size: mainButtonSize,
                isExpanded: isExpanded
            ) {
                toggleExpanded()
            }
            .overlay(alignment: .bottom) {
                Text("Offload")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
                    .offset(y: 14)
            }
            .offset(y: mainButtonYOffset)
        }
        .frame(width: slotWidth, height: mainButtonSize)
        .overlay(alignment: .top) {
            OffloadQuickActionTray(
                colorScheme: colorScheme,
                style: style,
                isExpanded: isExpanded,
                onQuickWrite: { triggerQuickAction(onQuickWrite) },
                onQuickVoice: { triggerQuickAction(onQuickVoice) }
            )
            .offset(y: quickActionYOffset + quickActionBounce)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Offload")
        .zIndex(1)
    }

    private func toggleExpanded() {
        if isExpanded {
            withAnimation(expansionAnimation) {
                isExpanded = false
            }
            quickActionBounce = 0
            return
        }

        quickActionBounce = 12
        withAnimation(expansionAnimation) {
            isExpanded = true
        }
        withAnimation(.spring(response: 0.28, dampingFraction: 0.5)) {
            quickActionBounce = -6
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            guard isExpanded else { return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                quickActionBounce = 0
            }
        }
    }

    private func triggerQuickAction(_ action: () -> Void) {
        withAnimation(expansionAnimation) {
            isExpanded = false
        }
        quickActionBounce = 0
        action()
    }
}

private struct OffloadMainButton: View {
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let size: CGFloat
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.primary(colorScheme, style: style).opacity(0.12))
                    .frame(width: size + 12, height: size + 12)

                Circle()
                    .fill(Theme.Colors.buttonDark(colorScheme))
                    .overlay(
                        Circle()
                            .stroke(Theme.Colors.primary(colorScheme, style: style).opacity(0.5), lineWidth: 1.5)
                    )
                    .frame(width: size, height: size)
                    .shadow(
                        color: Theme.Shadows.ambient(colorScheme),
                        radius: Theme.Shadows.elevationSm,
                        y: Theme.Shadows.offsetYSm
                    )

                AppIcon(name: Icons.add, size: 22)
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(isExpanded ? 45 : 0))
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isExpanded)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isExpanded ? "Close Offload actions" : "Offload")
        .accessibilityHint("Shows quick capture actions")
    }
}

private struct OffloadQuickActionButton: View {
    let title: String
    let iconName: String
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                AppIcon(name: iconName, size: 26)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)

                Text(title)
                    .font(Theme.Typography.caption2)
                    .foregroundStyle(Theme.Colors.textSecondary(colorScheme, style: style))
            }
            .frame(width: 64, height: 60)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private struct OffloadQuickActionTray: View {
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let isExpanded: Bool
    let onQuickWrite: () -> Void
    let onQuickVoice: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            OffloadQuickActionButton(
                title: "Write",
                iconName: Icons.write,
                colorScheme: colorScheme,
                style: style,
                action: onQuickWrite
            )

            OffloadQuickActionButton(
                title: "Voice",
                iconName: Icons.microphone,
                colorScheme: colorScheme,
                style: style,
                action: onQuickVoice
            )
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .opacity(isExpanded ? 1 : 0)
        .scaleEffect(isExpanded ? 1 : 0.6, anchor: .bottom)
        .allowsHitTesting(isExpanded)
        .accessibilityHidden(!isExpanded)
        .animation(Theme.Animations.springDefault, value: isExpanded)
    }
}

// MARK: - Tab Button

private struct TabButton: View {
    let tab: MainTabView.Tab
    let isSelected: Bool
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                AppIcon(name: isSelected ? tab.selectedIcon : tab.icon, size: 24)
                Text(tab.label)
                    .font(Theme.Typography.caption)
            }
            .foregroundStyle(
                isSelected
                    ? Theme.Colors.primary(colorScheme, style: style)
                    : Theme.Colors.textSecondary(colorScheme, style: style)
            )
            .frame(minWidth: 54, minHeight: 40)
            .frame(maxWidth: .infinity)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(Theme.Colors.secondary(colorScheme, style: style))
                            .opacity(Theme.Opacity.tabButtonSelection(colorScheme))
                            .frame(maxWidth: .infinity, minHeight: 44)
                    } else {
                        Color.clear
                    }
                }
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
    }
}

#Preview {
    MainTabView()
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
}
