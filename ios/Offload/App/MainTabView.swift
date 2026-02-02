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

// MARK: - Atomic Age Tab Bar

private struct FloatingTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let onQuickWrite: () -> Void
    let onQuickVoice: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            TabButton(
                tab: .home,
                isSelected: selectedTab == .home,
                colorScheme: colorScheme,
                style: style
            ) { selectedTab = .home }

            DiagonalDivider(colorScheme: colorScheme, style: style)

            TabButton(
                tab: .review,
                isSelected: selectedTab == .review,
                colorScheme: colorScheme,
                style: style
            ) { selectedTab = .review }

            DiagonalDivider(colorScheme: colorScheme, style: style)

            Spacer().frame(width: 80) // CTA space

            DiagonalDivider(colorScheme: colorScheme, style: style)

            TabButton(
                tab: .organize,
                isSelected: selectedTab == .organize,
                colorScheme: colorScheme,
                style: style
            ) { selectedTab = .organize }

            DiagonalDivider(colorScheme: colorScheme, style: style)

            TabButton(
                tab: .account,
                isSelected: selectedTab == .account,
                colorScheme: colorScheme,
                style: style
            ) { selectedTab = .account }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .padding(.horizontal, 12)
        .background(AtomicBarBackground(colorScheme: colorScheme, style: style))
        .overlay(alignment: .top) {
            OffloadCTA(
                colorScheme: colorScheme,
                style: style,
                onQuickWrite: onQuickWrite,
                onQuickVoice: onQuickVoice
            )
            .offset(y: -32)
        }
        .animation(Theme.Animations.mechanicalSlide, value: selectedTab)
    }
}

// MARK: - Atomic Bar Background

private struct AtomicBarBackground: View {
    let colorScheme: ColorScheme
    let style: ThemeStyle

    var body: some View {
        ZStack {
            // Warm gradient background
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "3E2723"),
                            Color(hex: "4E342E")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Linen texture overlay
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .linenOverlay(opacity: 0.03)

            // Double border
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Theme.Colors.primary(colorScheme, style: style).opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )

            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(Color(hex: "8D6E63").opacity(0.6), lineWidth: 0.5)
                .padding(1)
        }
        .shadow(color: Theme.Colors.primary(colorScheme, style: style).opacity(0.15), radius: 8, y: 4)
    }
}

// MARK: - Diagonal Divider

private struct DiagonalDivider: View {
    let colorScheme: ColorScheme
    let style: ThemeStyle

    var body: some View {
        Rectangle()
            .fill(Color(hex: "FFB300").opacity(0.3))
            .frame(width: 1, height: 24)
            .rotationEffect(.degrees(20))
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
    @State private var continuousRotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        Button(action: action) {
            ZStack {
                // 8-point starburst atomic symbol
                ForEach(0..<8) { i in
                    Capsule()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Theme.Colors.primary(colorScheme, style: style),
                                    Theme.Colors.secondary(colorScheme, style: style)
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 32
                            )
                        )
                        .frame(width: 8, height: 32)
                        .offset(y: -16)
                        .rotationEffect(.degrees(Double(i) * 45))
                }
                .rotationEffect(.degrees(isExpanded ? 45 : 0))
                .rotationEffect(.degrees(continuousRotation))
                .animation(.easeInOut(duration: 0.4), value: isExpanded)

                // Pulsing glow
                Circle()
                    .fill(Theme.Colors.primary(colorScheme, style: style).opacity(0.3))
                    .frame(width: size + 16, height: size + 16)
                    .scaleEffect(pulseScale)

                // Center circle
                Circle()
                    .fill(Theme.Colors.primary(colorScheme, style: style))
                    .frame(width: 48, height: 48)

                // Plus icon
                AppIcon(name: Icons.add, size: 22)
                    .foregroundStyle(.white)
                    .rotationEffect(.degrees(isExpanded ? 45 : 0))
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            // Continuous gentle rotation
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                continuousRotation = 360
            }

            // Pulse every 3 seconds
            startPulsing()
        }
        .accessibilityLabel(isExpanded ? "Close Offload actions" : "Offload")
        .accessibilityHint("Shows quick capture actions")
    }

    private func startPulsing() {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.6)) {
                pulseScale = 1.2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    pulseScale = 1.0
                }
            }
        }
    }
}

private struct OffloadQuickActionButton: View {
    let title: String
    let iconName: String
    let gradient: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Kidney-shaped button with gradient
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

                    AppIcon(name: iconName, size: 24)
                        .foregroundStyle(.white)
                }

                // Bebas Neue label
                Text(title.uppercased())
                    .font(.custom("BebasNeue-Regular", size: 12))
                    .tracking(0.6)
                    .foregroundStyle(.white)
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
        HStack(spacing: 20) {
            OffloadQuickActionButton(
                title: "Write",
                iconName: Icons.write,
                gradient: [
                    Theme.Colors.primary(colorScheme, style: style),
                    Color(hex: "FFB300")
                ],
                action: onQuickWrite
            )

            OffloadQuickActionButton(
                title: "Voice",
                iconName: Icons.microphone,
                gradient: [
                    Theme.Colors.secondary(colorScheme, style: style),
                    Color(hex: "00695C")
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
                ZStack {
                    // Kidney-shaped active indicator
                    if isSelected {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Theme.Colors.primary(colorScheme, style: style),
                                        Theme.Colors.primary(colorScheme, style: style).opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 32)
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Icon
                    AppIcon(name: isSelected ? tab.selectedIcon : tab.icon, size: 20)
                        .foregroundStyle(
                            isSelected
                                ? Color(hex: "FFF8E1")
                                : Color(hex: "8D6E63").opacity(0.7)
                        )
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                        .rotationEffect(.degrees(isSelected ? 5 : 0))
                }

                // MCM all-caps label (Bebas Neue style)
                Text(tab.label.uppercased())
                    .font(.custom("BebasNeue-Regular", size: 11))
                    .tracking(0.8)
                    .foregroundStyle(
                        isSelected
                            ? Theme.Colors.primary(colorScheme, style: style)
                            : Color(hex: "BCAAA4").opacity(0.6)
                    )

                // Top accent line for active
                if isSelected {
                    Rectangle()
                        .fill(Color(hex: "FFB300"))
                        .frame(width: 16, height: 2)
                        .offset(y: -2)
                        .transition(.scale.combined(with: .opacity))
                }
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
