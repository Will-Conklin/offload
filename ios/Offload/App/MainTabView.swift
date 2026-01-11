// Intent: Provide shallow navigation with a persistent capture entry point aligned to ADHD-friendly guardrails.
//
// Agent Navigation:
// - MainTabView: Tab shell + capture FAB
// - TimelineView: ADHD-friendly visual timeline tab (optional)
//
//  MainTabView.swift
//  Offload
//
//  Created by Claude Code on 12/30/25.
//

import SwiftData
import SwiftUI

struct MainTabView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var selectedTab: Tab = .captures
    @State private var showingCapture = false
    @AppStorage("showTimelineTab") private var showTimelineTab = true

    var body: some View {
        TabView(selection: $selectedTab) {
            CapturesView()
                .tabItem {
                    Label("Captures", systemImage: Icons.inbox)
                }
                .tag(Tab.captures)

            if showTimelineTab {
                TimelineView()
                    .tabItem {
                        Label("Timeline", systemImage: Icons.timeline)
                    }
                    .tag(Tab.timeline)
            }

            OrganizeView()
                .tabItem {
                    Label("Organize", systemImage: Icons.organize)
                }
                .tag(Tab.organize)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: Icons.settings)
                }
                .tag(Tab.settings)
        }
        .accessibilityLabel("Main tabs")
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                // Floating Action Button for quick capture
                Button {
                    showingCapture = true
                } label: {
                    Label {
                        Text("Capture")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.white)
                            .padding(.top, Theme.Spacing.xs)
                    } icon: {
                        Image(systemName: Icons.capture)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(Color.white)
                    }
                    .padding(.vertical, Theme.Spacing.sm)
                    .padding(.horizontal, Theme.Spacing.md)
                    .frame(minWidth: Theme.HitTarget.minimum.width,
                           minHeight: Theme.HitTarget.minimum.height)
                    .background(
                        Capsule()
                            .fill(Theme.Materials.glass)
                    )
                    .overlay(
                        Capsule()
                            .fill(Theme.Gradients.accentPrimary(colorScheme, style: themeManager.currentStyle))
                            .opacity(0.85)
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                Theme.Materials.glassOverlay(colorScheme).opacity(0.35),
                                lineWidth: 1
                            )
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(Theme.Colors.focusRing(colorScheme, style: themeManager.currentStyle), lineWidth: 2)
                    )
                    .shadow(
                        color: Theme.Shadows.floatingShadow(colorScheme),
                        radius: Theme.Shadows.elevationLg,
                        x: 0,
                        y: Theme.Shadows.elevationSm
                    )
                }
                .accessibilityLabel("Capture new entry")
                .accessibilityHint("Opens quick capture sheet; you can organize later")
            }
            .buttonStyle(PressableButtonStyle())
            .padding(.trailing, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xs)
            .background(Color.clear)
        }
        .sheet(isPresented: $showingCapture) {
            CaptureView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: showTimelineTab) { _, newValue in
            if !newValue, selectedTab == .timeline {
                selectedTab = .captures
            }
        }
    }

    enum Tab {
        case captures
        case timeline
        case organize
        case settings
    }
}

#Preview {
    MainTabView()
        .modelContainer(PersistenceController.preview)
        .environmentObject(ThemeManager.shared)
}
