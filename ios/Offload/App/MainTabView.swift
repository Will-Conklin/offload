//
//  MainTabView.swift
//  Offload
//
//  Flat design with floating pill tab bar and center capture button
//

import SwiftUI
import SwiftData

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
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.sm)
        }
        .sheet(isPresented: $showingCapture) {
            CaptureView()
        }
    }

    enum Tab: CaseIterable {
        case captures
        case plans
        case lists

        var icon: String {
            switch self {
            case .captures: return Icons.inbox
            case .plans: return Icons.plans
            case .lists: return Icons.lists
            }
        }

        var label: String {
            switch self {
            case .captures: return "Captures"
            case .plans: return "Plans"
            case .lists: return "Lists"
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
            CapturesView()
        case .plans:
            OrganizeView(scope: .plans)
        case .lists:
            OrganizeView(scope: .lists)
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
            // Left tabs
            TabButton(
                tab: .captures,
                isSelected: selectedTab == .captures,
                colorScheme: colorScheme,
                style: style
            ) { selectedTab = .captures }

            TabButton(
                tab: .plans,
                isSelected: selectedTab == .plans,
                colorScheme: colorScheme,
                style: style
            ) { selectedTab = .plans }

            // Center capture button
            CaptureButton(
                colorScheme: colorScheme,
                style: style,
                action: onCaptureTap
            )
            .padding(.horizontal, Theme.Spacing.sm)

            // Right tabs
            TabButton(
                tab: .lists,
                isSelected: selectedTab == .lists,
                colorScheme: colorScheme,
                style: style
            ) { selectedTab = .lists }
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            Capsule()
                .fill(Theme.Colors.surface(colorScheme, style: style))
                .overlay(
                    Capsule()
                        .stroke(Theme.Colors.border(colorScheme, style: style), lineWidth: 1)
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
                Image(systemName: tab.icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                Text(tab.label)
                    .font(.system(size: 10, weight: isSelected ? .medium : .regular))
            }
            .foregroundStyle(
                isSelected
                    ? Theme.Colors.primary(colorScheme, style: style)
                    : Theme.Colors.textSecondary(colorScheme, style: style)
            )
            .frame(minWidth: 56, minHeight: 44)
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
            Image(systemName: Icons.capture)
                .font(.system(size: 22, weight: .semibold))
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
