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
        TabContent(selectedTab: selectedTab, navigateToOrganize: { selectedTab = .organize })
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
                    .environmentObject(themeManager)
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
    let navigateToOrganize: () -> Void

    var body: some View {
        switch selectedTab {
        case .home:
            HomeView(navigateToOrganize: navigateToOrganize)
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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private var barHeight: CGFloat { TabShellLayoutPolicy.barHeight(for: dynamicTypeSize) }

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
                    .fill(Theme.Colors.borderMuted(colorScheme, style: style).opacity(Theme.TabShell.dividerOpacityLight))
                    .frame(width: Theme.TabShell.dividerWidth, height: Theme.TabShell.dividerHeight)

                TabButton(
                    tab: .review,
                    isSelected: selectedTab == .review,
                    colorScheme: colorScheme,
                    style: style
                ) { selectedTab = .review }

                Rectangle()
                    .fill(Theme.Colors.borderMuted(colorScheme, style: style).opacity(Theme.TabShell.dividerOpacityLight))
                    .frame(width: Theme.TabShell.dividerWidth, height: Theme.TabShell.dividerHeight)

                Spacer().frame(width: Theme.TabShell.mainButtonSlotWidth)

                Rectangle()
                    .fill(Theme.Colors.borderMuted(colorScheme, style: style).opacity(Theme.TabShell.dividerOpacityLight))
                    .frame(width: Theme.TabShell.dividerWidth, height: Theme.TabShell.dividerHeight)

                TabButton(
                    tab: .organize,
                    isSelected: selectedTab == .organize,
                    colorScheme: colorScheme,
                    style: style
                ) { selectedTab = .organize }

                Rectangle()
                    .fill(Theme.Colors.borderMuted(colorScheme, style: style).opacity(Theme.TabShell.dividerOpacityLight))
                    .frame(width: Theme.TabShell.dividerWidth, height: Theme.TabShell.dividerHeight)

                TabButton(
                    tab: .account,
                    isSelected: selectedTab == .account,
                    colorScheme: colorScheme,
                    style: style
                ) { selectedTab = .account }
            }
            .frame(height: barHeight)
            .padding(.horizontal, Theme.TabShell.barHorizontalPadding)

            // CTA integrated into bar (halfway overlap)
            OffloadCTA(
                colorScheme: colorScheme,
                style: style,
                onQuickWrite: onQuickWrite,
                onQuickVoice: onQuickVoice
            )
            .offset(y: 0)
        }
        .frame(height: barHeight)
        .accessibilityIdentifier(TabShellAccessibility.tabBarIdentifier)
        .animation(TabShellMotionPolicy.animation(.easeInOut(duration: 0.4), reduceMotion: reduceMotion), value: selectedTab)
    }
}

// MARK: - Atomic Bar Background

private struct AtomicBarBackground: View {
    let colorScheme: ColorScheme
    let style: ThemeStyle

    var body: some View {
        UnevenRoundedRectangle(
            cornerRadii: RectangleCornerRadii(
                topLeading: Theme.TabShell.barTopCornerRadius,
                bottomLeading: 0,
                bottomTrailing: 0,
                topTrailing: Theme.TabShell.barTopCornerRadius
            ),
            style: .continuous
        )
        .fill(Theme.Colors.surface(colorScheme, style: style))
        .shadow(
            color: Color.black.opacity(Theme.TabShell.barShadowOpacity),
            radius: Theme.TabShell.barShadowRadius,
            y: Theme.TabShell.barShadowOffsetY
        )
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var scaledMainButtonSize = Theme.TabShell.mainButtonSize
    @ScaledMetric(relativeTo: .body) private var scaledQuickActionLift = Theme.TabShell.quickActionLift

    private var slotWidth: CGFloat { scaledMainButtonSize + Theme.TabShell.mainButtonSlotPadding }
    private var mainButtonYOffset: CGFloat { Theme.TabShell.mainButtonVerticalOffset }
    private var quickActionYOffset: CGFloat { mainButtonYOffset - quickActionLift }
    private var quickActionLift: CGFloat { scaledQuickActionLift }

    private var expansionAnimation: Animation? {
        TabShellMotionPolicy.animation(.spring(response: 0.4, dampingFraction: 0.6), reduceMotion: reduceMotion)
    }

    var body: some View {
        ZStack {
            OffloadMainButton(
                colorScheme: colorScheme,
                style: style,
                size: scaledMainButtonSize,
                isExpanded: isExpanded
            ) {
                toggleExpanded()
            }
            .offset(y: mainButtonYOffset)
        }
        .frame(width: slotWidth, height: scaledMainButtonSize)
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
        .accessibilityLabel(TabShellAccessibility.offloadGroupLabel)
        .accessibilityIdentifier(TabShellAccessibility.offloadGroupIdentifier)
        .zIndex(1)
    }

    /// Toggles quick-action expansion and applies motion policy compliant bounce behavior.
    private func toggleExpanded() {
        if isExpanded {
            withAnimation(expansionAnimation) {
                isExpanded = false
            }
            quickActionBounce = 0
            return
        }

        quickActionBounce = TabShellMotionPolicy.initialQuickActionBounce(reduceMotion: reduceMotion)
        withAnimation(expansionAnimation) {
            isExpanded = true
        }
        guard TabShellMotionPolicy.shouldAnimateBounce(reduceMotion: reduceMotion) else { return }
        withAnimation(TabShellMotionPolicy.animation(.spring(response: 0.28, dampingFraction: 0.5), reduceMotion: reduceMotion)) {
            quickActionBounce = TabShellMotionPolicy.overshootQuickActionBounce(reduceMotion: reduceMotion)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Theme.TabShell.quickActionBounceSettleDelay) {
            guard isExpanded else { return }
            withAnimation(TabShellMotionPolicy.animation(.spring(response: 0.25, dampingFraction: 0.75), reduceMotion: reduceMotion)) {
                quickActionBounce = 0
            }
        }
    }

    /// Collapses the quick-action tray before executing the selected capture action.
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

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            ZStack {
                // Subtle outer glow
                Circle()
                    .fill(Theme.Colors.primary(colorScheme, style: style).opacity(0.15))
                    .frame(width: size + Theme.TabShell.mainButtonGlowDelta, height: size + Theme.TabShell.mainButtonGlowDelta)

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
                AppIcon(name: Icons.add, size: Theme.TabShell.mainButtonIconSize)
                    .foregroundStyle(Theme.Colors.accentButtonText(colorScheme, style: style))
                    .rotationEffect(.degrees(isExpanded ? 45 : 0))
            }
        }
        .buttonStyle(.plain)
        .frame(
            minWidth: Theme.TabShell.mainButtonControlSize,
            minHeight: Theme.TabShell.mainButtonControlSize
        )
        .animation(TabShellMotionPolicy.animation(.spring(response: 0.4, dampingFraction: 0.7), reduceMotion: reduceMotion), value: isExpanded)
        .accessibilityLabel(isExpanded ? TabShellAccessibility.offloadMainExpandedLabel : TabShellAccessibility.offloadMainCollapsedLabel)
        .accessibilityHint(TabShellAccessibility.offloadMainHint)
        .accessibilityIdentifier(TabShellAccessibility.mainButtonIdentifier)
        .accessibilitySortPriority(TabShellAccessibility.mainButtonSortPriority)
        .accessibilityAddTraits(.isButton)
    }
}

private struct OffloadQuickActionButton: View {
    let title: String
    let iconName: String
    let gradient: [Color]
    let accessibilityIdentifier: String
    let accessibilitySortPriority: Double
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    @ScaledMetric(relativeTo: .body) private var scaledButtonSize = Theme.TabShell.quickActionButtonSize
    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        Button(action: action) {
            // Kidney-shaped button with solid color
            ZStack {
                RoundedRectangle(cornerRadius: Theme.TabShell.quickActionCornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: scaledButtonSize, height: scaledButtonSize)

                ZStack {
                    AppIcon(name: iconName, size: Theme.TabShell.mainButtonIconSize)
                        .foregroundStyle(Theme.Colors.accentButtonText(colorScheme, style: style))
                }
                .frame(width: scaledButtonSize, height: scaledButtonSize)
            }
        }
        .buttonStyle(.plain)
        .frame(
            minWidth: Theme.HitTarget.minimum.width,
            minHeight: Theme.HitTarget.minimum.height
        )
        .accessibilityLabel(title)
        .accessibilityHint("Opens \(title) \(TabShellAccessibility.quickActionHintSuffix)")
        .accessibilityIdentifier(accessibilityIdentifier)
        .accessibilitySortPriority(accessibilitySortPriority)
        .accessibilityAddTraits(.isButton)
    }
}

private struct OffloadQuickActionTray: View {
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let isExpanded: Bool
    let onQuickWrite: () -> Void
    let onQuickVoice: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .top, spacing: TabShellLayoutPolicy.quickActionTraySpacing(for: dynamicTypeSize)) {
            OffloadQuickActionButton(
                title: TabShellAccessibility.quickWriteLabel,
                iconName: Icons.write,
                gradient: [
                    Theme.Colors.primary(colorScheme, style: style),
                    Theme.Colors.primary(colorScheme, style: style),
                ],
                accessibilityIdentifier: TabShellAccessibility.quickWriteIdentifier,
                accessibilitySortPriority: TabShellAccessibility.quickWriteSortPriority,
                action: onQuickWrite
            )

            OffloadQuickActionButton(
                title: TabShellAccessibility.quickVoiceLabel,
                iconName: Icons.microphone,
                gradient: [
                    Theme.Colors.secondary(colorScheme, style: style),
                    Theme.Colors.secondary(colorScheme, style: style),
                ],
                accessibilityIdentifier: TabShellAccessibility.quickVoiceIdentifier,
                accessibilitySortPriority: TabShellAccessibility.quickVoiceSortPriority,
                action: onQuickVoice
            )
        }
        .padding(.horizontal, Theme.TabShell.quickActionTrayHorizontalPadding)
        .padding(.vertical, Theme.TabShell.quickActionTrayVerticalPadding)
        .opacity(isExpanded ? 1 : 0)
        .scaleEffect(isExpanded ? 1 : 0.6, anchor: .bottom)
        .allowsHitTesting(isExpanded)
        .accessibilityHidden(!isExpanded)
        .accessibilityIdentifier(TabShellAccessibility.offloadQuickTrayIdentifier)
        .animation(TabShellMotionPolicy.animation(.spring(response: 0.4, dampingFraction: 0.7), reduceMotion: reduceMotion), value: isExpanded)
    }
}

// MARK: - Tab Button

private struct TabButton: View {
    let tab: MainTabView.Tab
    let isSelected: Bool
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Spacer()
                    .frame(height: Theme.TabShell.tabTopInset)

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
                            .frame(width: Theme.TabShell.tabIconCircleSize, height: Theme.TabShell.tabIconCircleSize)
                            .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                    } else {
                        Circle()
                            .fill(Theme.Colors.borderMuted(colorScheme, style: style).opacity(0.08))
                            .frame(width: Theme.TabShell.tabIconCircleSize, height: Theme.TabShell.tabIconCircleSize)
                    }

                    // Thin SF Symbol icon
                    Image(systemName: tab.iconName)
                        .font(.system(size: Theme.TabShell.tabIconFontSize, weight: isSelected ? .regular : .light))
                        .imageScale(.medium)
                        .foregroundStyle(
                            isSelected
                                ? Theme.Colors.primary(colorScheme, style: style)
                                : Theme.Colors.textSecondary(colorScheme, style: style)
                        )
                        .frame(width: Theme.TabShell.tabIconFrameSize, height: Theme.TabShell.tabIconFrameSize, alignment: .center)
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                }
                .frame(
                    minWidth: Theme.TabShell.tabButtonControlSize,
                    minHeight: Theme.TabShell.tabButtonControlSize
                )

                // Label
                Text(tab.label)
                    .font(
                        .system(
                            size: dynamicTypeSize.isAccessibilitySize
                                ? Theme.TabShell.tabLabelAccessibilityFontSize
                                : Theme.TabShell.tabLabelFontSize,
                            weight: .medium,
                            design: .default
                        )
                    )
                    .foregroundStyle(
                        isSelected
                            ? Theme.Colors.primary(colorScheme, style: style)
                            : Theme.Colors.textSecondary(colorScheme, style: style)
                    )
                    .lineLimit(TabShellLayoutPolicy.tabLabelLineLimit(for: dynamicTypeSize))
                    .minimumScaleFactor(TabShellLayoutPolicy.tabLabelMinimumScaleFactor(for: dynamicTypeSize))
                    .multilineTextAlignment(.center)

                Spacer()
                    .frame(height: Theme.TabShell.tabBottomInset)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(TabShellMotionPolicy.animation(.spring(response: 0.3, dampingFraction: 0.7), reduceMotion: reduceMotion), value: isSelected)
        .accessibilityLabel(tab.label)
        .accessibilityValue(isSelected ? TabShellAccessibility.tabSelectionSelectedValue : TabShellAccessibility.tabSelectionNotSelectedValue)
        .accessibilityHint("Switches to \(tab.label)")
        .accessibilityIdentifier(TabShellAccessibility.identifier(for: tab))
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    MainTabView()
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
}
