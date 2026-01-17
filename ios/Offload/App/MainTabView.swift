//
//  MainTabView.swift
//  Offload
//
//  Flat design with floating pill tab bar
//

import SwiftUI
import SwiftData

// AGENT NAV
// - Tabs
// - Content
// - Floating Tab Bar
// - Tab Buttons

struct MainTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedTab: Tab = .capture

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        TabContent(selectedTab: selectedTab)
            .safeAreaInset(edge: .bottom) {
                FloatingTabBar(
                    selectedTab: $selectedTab,
                    colorScheme: colorScheme,
                    style: style
                )
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.top, Theme.Spacing.sm)
                .padding(.bottom, Theme.Spacing.sm)
            }
    }

    enum Tab: CaseIterable {
        case capture
        case organize

        var icon: String {
            switch self {
            case .capture: return Icons.captureList
            case .organize: return Icons.organize
            }
        }

        var selectedIcon: String {
            switch self {
            case .capture: return Icons.captureListSelected
            case .organize: return Icons.organizeSelected
            }
        }

        var label: String {
            switch self {
            case .capture: return "Capture"
            case .organize: return "Organize"
            }
        }
    }
}

// MARK: - Tab Content

private struct TabContent: View {
    let selectedTab: MainTabView.Tab

    var body: some View {
        switch selectedTab {
        case .capture:
            CaptureView()
        case .organize:
            OrganizeView()
        }
    }
}

// MARK: - Floating Tab Bar

private struct FloatingTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    let colorScheme: ColorScheme
    let style: ThemeStyle

    var body: some View {
        HStack(spacing: 0) {
            // Left tab
            TabButton(
                tab: .capture,
                isSelected: selectedTab == .capture,
                colorScheme: colorScheme,
                style: style
            ) { selectedTab = .capture }

            Spacer()

            // Right tab
            TabButton(
                tab: .organize,
                isSelected: selectedTab == .organize,
                colorScheme: colorScheme,
                style: style
            ) { selectedTab = .organize }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.md)
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
            .frame(minWidth: 80, minHeight: 64)
            .background(
                Group {
                    if isSelected {
                        Theme.Colors.secondary(colorScheme, style: style)
                            .opacity(Theme.Opacity.tabButtonSelection(colorScheme))
                            .clipShape(Capsule())
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
