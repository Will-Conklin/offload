// Purpose: App entry points and root navigation.
// Authority: Code-level
// Governed by: AGENTS.md
// Additional instructions: Keep navigation flow consistent with MainTabView -> NavigationStack -> sheets.

//  Flat design with floating pill tab bar

import SwiftData
import SwiftUI

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
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
    }

    enum Tab: CaseIterable {
        case home
        case review
        case organize
        case account

        var iconName: String {
            switch self {
            case .home: "house"
            case .review: "tray"
            case .organize: "folder"
            case .account: "person"
            }
        }

        var label: String {
            switch self {
            case .home: "Home"
            case .review: "Review"
            case .organize: "Organize"
            case .account: "Account"
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

// MARK: - Atomic Age Tab Bar

private struct FloatingTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onQuickWrite: () -> Void
    let onQuickVoice: () -> Void

    var body: some View {
        ZStack {
            // Bar connects to bottom
            AtomicBarBackground(colorScheme: colorScheme, style: style)
                .ignoresSafeArea(edges: .bottom)

            HStack(spacing: 0) {
                TabButton(
                    tab: .home,
                    isSelected: selectedTab == .home,
                    colorScheme: colorScheme,
                    style: style
                ) { selectedTab = .home }

                Rectangle()
                    .fill(Theme.Colors.borderMuted(colorScheme, style: style).opacity(0.3))
                    .frame(width: 1, height: 24)

                TabButton(
                    tab: .review,
                    isSelected: selectedTab == .review,
                    colorScheme: colorScheme,
                    style: style
                ) { selectedTab = .review }

                Rectangle()
                    .fill(Theme.Colors.borderMuted(colorScheme, style: style).opacity(0.3))
                    .frame(width: 1, height: 24)

                Spacer().frame(width: 80) // CTA space

                Rectangle()
                    .fill(Theme.Colors.borderMuted(colorScheme, style: style).opacity(0.3))
                    .frame(width: 1, height: 24)

                TabButton(
                    tab: .organize,
                    isSelected: selectedTab == .organize,
                    colorScheme: colorScheme,
                    style: style
                ) { selectedTab = .organize }

                Rectangle()
                    .fill(Theme.Colors.borderMuted(colorScheme, style: style).opacity(0.3))
                    .frame(width: 1, height: 24)

                TabButton(
                    tab: .account,
                    isSelected: selectedTab == .account,
                    colorScheme: colorScheme,
                    style: style
                ) { selectedTab = .account }
            }
            .frame(height: 60)
            .padding(.horizontal, 8)

            // CTA integrated into bar (halfway overlap)
            OffloadCTA(
                colorScheme: colorScheme,
                style: style,
                onQuickWrite: onQuickWrite,
                onQuickVoice: onQuickVoice
            )
            .offset(y: 0)
        }
        .frame(height: 60)
        .animation(Theme.Animations.mechanicalSlide, value: selectedTab)
    }
}

// MARK: - Atomic Bar Background

private struct AtomicBarBackground: View {
    let colorScheme: ColorScheme
    let style: ThemeStyle

    var body: some View {
        UnevenRoundedRectangle(
            cornerRadii: RectangleCornerRadii(
                topLeading: 24,
                bottomLeading: 0,
                bottomTrailing: 0,
                topTrailing: 24
            ),
            style: .continuous
        )
        .fill(Theme.Colors.surface(colorScheme, style: style))
        .shadow(color: Color.black.opacity(0.1), radius: 12, y: -2)
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
                // Subtle outer glow
                Circle()
                    .fill(Theme.Colors.primary(colorScheme, style: style).opacity(0.15))
                    .frame(width: size + 8, height: size + 8)

                // Main circle with gradient
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Theme.Colors.primary(colorScheme, style: style),
                                Theme.Colors.primary(colorScheme, style: style).opacity(0.9),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size, height: size)

                // Plus icon
                AppIcon(name: Icons.add, size: 24)
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(isExpanded ? 45 : 0))
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isExpanded)
        .accessibilityLabel(isExpanded ? "Close Offload actions" : "Offload")
        .accessibilityHint("Shows quick capture actions")
    }
}

private struct OffloadQuickActionButton: View {
    let title: String
    let iconName: String
    let gradient: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            // Kidney-shaped button with solid color
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                ZStack {
                    AppIcon(name: iconName, size: 24)
                        .foregroundStyle(.white)
                }
                .frame(width: 56, height: 56)
            }
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
        HStack(alignment: .top, spacing: 20) {
            OffloadQuickActionButton(
                title: "Write",
                iconName: Icons.write,
                gradient: [
                    Theme.Colors.primary(colorScheme, style: style),
                    Theme.Colors.primary(colorScheme, style: style),
                ],
                action: onQuickWrite
            )

            OffloadQuickActionButton(
                title: "Voice",
                iconName: Icons.microphone,
                gradient: [
                    Theme.Colors.secondary(colorScheme, style: style),
                    Theme.Colors.secondary(colorScheme, style: style),
                ],
                action: onQuickVoice
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .opacity(isExpanded ? 1 : 0)
        .scaleEffect(isExpanded ? 1 : 0.6, anchor: .bottom)
        .allowsHitTesting(isExpanded)
        .accessibilityHidden(!isExpanded)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isExpanded)
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
            VStack(spacing: 4) {
                Spacer()
                    .frame(height: 8)

                ZStack {
                    // Circular background with gradient for active
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Theme.Colors.primary(colorScheme, style: style).opacity(0.2),
                                        Theme.Colors.primary(colorScheme, style: style).opacity(0.1),
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Circle()
                            .fill(Theme.Colors.borderMuted(colorScheme, style: style).opacity(0.08))
                            .frame(width: 44, height: 44)
                    }

                    // Thin SF Symbol icon
                    Image(systemName: tab.iconName)
                        .font(.system(size: 22, weight: isSelected ? .regular : .light))
                        .imageScale(.medium)
                        .foregroundStyle(
                            isSelected
                                ? Theme.Colors.primary(colorScheme, style: style)
                                : Theme.Colors.textSecondary(colorScheme, style: style)
                        )
                        .frame(width: 24, height: 24, alignment: .center)
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                }

                // Label
                Text(tab.label)
                    .font(.system(size: 10, weight: .medium, design: .default))
                    .foregroundStyle(
                        isSelected
                            ? Theme.Colors.primary(colorScheme, style: style)
                            : Theme.Colors.textSecondary(colorScheme, style: style)
                    )

                Spacer()
                    .frame(height: 6)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .accessibilityLabel(tab.label)
    }
}

#Preview {
    MainTabView()
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
}
