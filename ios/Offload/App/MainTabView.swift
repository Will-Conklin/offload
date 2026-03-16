// Purpose: App entry points and root navigation.
// Authority: Code-level
// Governed by: CLAUDE.md
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
            // ⌘N — open compose from anywhere on iPad with keyboard
            .background(
                Button("New Capture") { quickCaptureMode = .write }
                    .keyboardShortcut("n", modifiers: .command)
                    .accessibilityHidden(true)
                    .frame(width: 0, height: 0)
                    .opacity(0)
            )
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .body) private var scaledMainButtonSize = Theme.TabShell.mainButtonSize

    private var slotWidth: CGFloat { scaledMainButtonSize + Theme.TabShell.mainButtonSlotPadding }
    private var mainButtonYOffset: CGFloat { Theme.TabShell.mainButtonVerticalOffset }

    var body: some View {
        OffloadMainButton(
            colorScheme: colorScheme,
            style: style,
            size: scaledMainButtonSize,
            onTap: onQuickWrite,
            onLongPress: onQuickVoice
        )
        .offset(y: mainButtonYOffset)
        .frame(width: slotWidth, height: scaledMainButtonSize)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(TabShellAccessibility.offloadGroupLabel)
        .accessibilityHint("Tap to write a capture. Long press to capture by voice.")
        .accessibilityAction(named: "Quick Write") { onQuickWrite() }
        .accessibilityAction(named: "Quick Voice") { onQuickVoice() }
        .accessibilityIdentifier(TabShellAccessibility.offloadGroupIdentifier)
        .accessibilityAddTraits(.isButton)
        .zIndex(1)
    }
}

private struct OffloadMainButton: View {
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let size: CGFloat
    /// Fired on a short tap — opens write compose sheet.
    let onTap: () -> Void
    /// Fired on a long press (≥ 0.5 s) — opens voice compose sheet.
    let onLongPress: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressStart: Date?
    @State private var isHighlighted = false

    private let longPressDuration: TimeInterval = 0.5

    var body: some View {
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
                .scaleEffect(isHighlighted ? 0.92 : 1.0)
                .animation(
                    TabShellMotionPolicy.animation(.spring(response: 0.25, dampingFraction: 0.7), reduceMotion: reduceMotion),
                    value: isHighlighted
                )

            // Plus icon
            AppIcon(name: Icons.add, size: Theme.TabShell.mainButtonIconSize)
                .foregroundStyle(Theme.Colors.accentButtonText(colorScheme, style: style))
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if pressStart == nil {
                        pressStart = Date()
                        withAnimation(TabShellMotionPolicy.animation(.spring(response: 0.2, dampingFraction: 0.7), reduceMotion: reduceMotion)) {
                            isHighlighted = true
                        }
                    }
                }
                .onEnded { _ in
                    guard let start = pressStart else { return }
                    let duration = Date().timeIntervalSince(start)
                    pressStart = nil
                    withAnimation(TabShellMotionPolicy.animation(.spring(response: 0.2, dampingFraction: 0.7), reduceMotion: reduceMotion)) {
                        isHighlighted = false
                    }
                    if duration >= longPressDuration {
                        onLongPress()
                    } else {
                        onTap()
                    }
                }
        )
        .frame(
            minWidth: Theme.TabShell.mainButtonControlSize,
            minHeight: Theme.TabShell.mainButtonControlSize
        )
        .accessibilityIdentifier(TabShellAccessibility.mainButtonIdentifier)
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
