//
//  MainTabView.swift
//  Offload
//
//  Flat design with floating pill tab bar and center capture button
//

import SwiftUI
import SwiftData

// AGENT NAV
// - Tabs
// - Content
// - Floating Tab Bar
// - Tab Buttons
// - Capture Button

struct MainTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedTab: Tab = .captures
    @State private var showingCapture = false

    private var style: ThemeStyle { themeManager.currentStyle }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            TabContent(selectedTab: selectedTab)
                .ignoresSafeArea(edges: .bottom)

            // Floating tab bar
            FloatingTabBar(
                selectedTab: $selectedTab,
                onCaptureTap: { showingCapture = true },
                colorScheme: colorScheme,
                style: style
            )
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.bottom, Theme.Spacing.sm)
        }
        .sheet(isPresented: $showingCapture) {
            CaptureComposeView()
        }
    }

    enum Tab: CaseIterable {
        case captures
        case organize

        var icon: String {
            switch self {
            case .captures: return Icons.captures
            case .organize: return Icons.organize
            }
        }

        var selectedIcon: String {
            switch self {
            case .captures: return Icons.capturesSelected
            case .organize: return Icons.organizeSelected
            }
        }

        var label: String {
            switch self {
            case .captures: return "Captures"
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
        case .captures:
            CapturesListView()
        case .organize:
            OrganizeView()
        }
    }
}

// MARK: - Floating Tab Bar

private struct FloatingTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    let onCaptureTap: () -> Void
    let colorScheme: ColorScheme
    let style: ThemeStyle

    var body: some View {
        HStack(spacing: 0) {
            // Left tab
            TabButton(
                tab: .captures,
                isSelected: selectedTab == .captures,
                colorScheme: colorScheme,
                style: style
            ) { selectedTab = .captures }

            // Center capture button
            CaptureButton(
                colorScheme: colorScheme,
                style: style,
                action: onCaptureTap
            )
            .padding(.horizontal, Theme.Spacing.sm)

            // Right tab
            TabButton(
                tab: .organize,
                isSelected: selectedTab == .organize,
                colorScheme: colorScheme,
                style: style
            ) { selectedTab = .organize }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            Capsule()
                .fill(Theme.Colors.surface(colorScheme, style: style))
                .overlay(
                    Capsule()
                        .stroke(Theme.Colors.border(colorScheme, style: style), lineWidth: 2)
                )
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
                AppIcon(name: isSelected ? tab.selectedIcon : tab.icon, size: 36)
                Text(tab.label)
                    .font(.system(size: 12, weight: isSelected ? .medium : .regular))
            }
            .foregroundStyle(
                isSelected
                    ? Theme.Colors.primary(colorScheme, style: style)
                    : Theme.Colors.textSecondary(colorScheme, style: style)
            )
            .frame(minWidth: 80, minHeight: 64)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
    }
}

// MARK: - Center Capture Button

private struct CaptureButton: View {
    let colorScheme: ColorScheme
    let style: ThemeStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AppIcon(name: Icons.capture, size: 22)
                .foregroundStyle(Color.white)
                .frame(width: 52, height: 52)
                .background(
                    Circle()
                        .fill(Theme.Colors.primary(colorScheme, style: style))
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Capture")
        .accessibilityHint("Opens quick capture sheet")
    }
}

#Preview {
    MainTabView()
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
}
